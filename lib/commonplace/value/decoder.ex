defmodule Commonplace.Value.Decoder do
  @moduledoc false

  alias Commonplace.Value.{Domain, Encoder, Error, Limits, Pointer}

  @max_safe_integer 9_007_199_254_740_991

  @spec decode(binary(), keyword()) ::
          {:ok, Domain.normalized_term(), Commonplace.Value.Metrics.t()}
          | {:error, Error.t()}
  def decode(bytes, opts \\ []) do
    limits = Keyword.get(opts, :limits, %Limits{})

    with :ok <- validate_limits(limits),
         :ok <- check_input_size(bytes, limits),
         {:ok, parsed} <- parse(bytes),
         {:ok, interoperable} <- normalize_decoded_numbers(parsed),
         {:ok, normalized, metrics} <- validate_domain(interoperable, opts),
         :ok <- verify_canonical(bytes, normalized) do
      {:ok, normalized, %{metrics | encoded_byte_length: byte_size(bytes)}}
    end
  end

  defp validate_limits(limits) do
    case Limits.validate(limits) do
      :ok -> :ok
      {:error, :invalid_limits} -> error(:invalid_limits)
    end
  end

  defp check_input_size(bytes, limits) when is_binary(bytes) do
    actual = byte_size(bytes)

    if actual > limits.max_bytes do
      error(:max_bytes_exceeded, "", limits.max_bytes, actual)
    else
      :ok
    end
  end

  defp check_input_size(_bytes, _limits), do: error(:invalid_json)

  defp parse(bytes) do
    cond do
      not String.valid?(bytes) ->
        error(:invalid_utf8)

      true ->
        case JSON.decode(bytes) do
          {:ok, term} -> {:ok, term}
          {:error, parser_error} -> error(parser_reason(bytes, parser_error))
        end
    end
  end

  defp parser_reason(bytes, {:invalid_byte, offset, byte})
       when byte in [0x20, 0x09, 0x0A, 0x0D] do
    prefix = binary_part(bytes, 0, offset)
    suffix = binary_part(bytes, offset, byte_size(bytes) - offset)

    if String.trim(suffix) != "" and match?({:ok, _term}, JSON.decode(prefix)) do
      :trailing_data
    else
      :invalid_json
    end
  end

  defp parser_reason(_bytes, _parser_error), do: :invalid_json

  defp normalize_decoded_numbers(term), do: normalize_decoded_numbers(term, [])

  defp normalize_decoded_numbers(term, path)
       when is_integer(term) and (term < -@max_safe_integer or term > @max_safe_integer) do
    spelling = Integer.to_string(term)

    case parse_finite_float(spelling) do
      {:ok, number} ->
        if Encoder.encode(number) == spelling do
          {:ok, number}
        else
          error(:number_not_interoperable, Pointer.render(path))
        end

      :error ->
        error(:number_not_interoperable, Pointer.render(path))
    end
  end

  defp normalize_decoded_numbers(term, _path)
       when is_integer(term) or is_float(term) or is_binary(term) or is_boolean(term) or
              is_nil(term),
       do: {:ok, term}

  defp normalize_decoded_numbers(term, path) when is_list(term) do
    term
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {child, index}, {:ok, acc} ->
      case normalize_decoded_numbers(child, [index | path]) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, _error} = failure -> {:halt, failure}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      failure -> failure
    end
  end

  defp normalize_decoded_numbers(term, path) when is_map(term) do
    Enum.reduce_while(term, {:ok, %{}}, fn {key, child}, {:ok, acc} ->
      case normalize_decoded_numbers(child, [key | path]) do
        {:ok, normalized} -> {:cont, {:ok, Map.put(acc, key, normalized)}}
        {:error, _error} = failure -> {:halt, failure}
      end
    end)
  end

  defp parse_finite_float(spelling) do
    try do
      case Float.parse(spelling) do
        {number, ""} when number == number and number - number == 0.0 -> {:ok, number}
        _other -> :error
      end
    rescue
      ArgumentError -> :error
    end
  end

  defp validate_domain(term, opts) do
    case Domain.validate(term, opts) do
      {:ok, normalized, metrics} -> {:ok, normalized, metrics}
      {:error, %Error{} = error} -> {:error, %{error | operation: :decode}}
    end
  end

  defp verify_canonical(bytes, normalized) do
    if Encoder.encode(normalized) == bytes do
      :ok
    else
      error(:non_canonical_json)
    end
  end

  defp error(reason), do: error(reason, "", nil, nil)
  defp error(reason, path), do: error(reason, path, nil, nil)

  defp error(reason, path, limit, actual) do
    {:error,
     %Error{
       operation: :decode,
       reason: reason,
       path: path,
       limit: limit,
       actual: actual
     }}
  end
end
