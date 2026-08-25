defmodule Commonplace.Value.Domain do
  @moduledoc false

  alias Commonplace.Value.{Error, Limits, Pointer}

  @max_safe_integer 9_007_199_254_740_991

  @type normalized_term ::
          nil
          | boolean()
          | integer()
          | float()
          | String.t()
          | [normalized_term()]
          | %{String.t() => normalized_term()}

  @spec validate(term(), keyword()) :: {:ok, normalized_term()} | {:error, Error.t()}
  def validate(term, opts \\ []) do
    with :ok <- validate_limits(Keyword.get(opts, :limits, %Limits{})) do
      normalize(term, [])
    end
  end

  defp validate_limits(limits) do
    case Limits.validate(limits) do
      :ok -> :ok
      {:error, :invalid_limits} -> error(:invalid_limits, [])
    end
  end

  defp normalize(nil, _path), do: {:ok, nil}
  defp normalize(true, _path), do: {:ok, true}
  defp normalize(false, _path), do: {:ok, false}

  defp normalize(term, path) when is_atom(term), do: error(:atom_not_allowed, path)

  defp normalize(term, _path)
       when is_integer(term) and term >= -@max_safe_integer and term <= @max_safe_integer,
       do: {:ok, term}

  defp normalize(term, path) when is_integer(term), do: error(:integer_out_of_range, path)

  defp normalize(term, path) when is_float(term) do
    cond do
      not finite?(term) ->
        error(:non_finite_number, path)

      term == 0.0 ->
        {:ok, 0}

      integral_in_safe_range?(term) ->
        {:ok, trunc(term)}

      true ->
        {:ok, term}
    end
  end

  defp normalize(term, path) when is_binary(term) do
    if String.valid?(term), do: {:ok, term}, else: error(:invalid_utf8, path)
  end

  defp normalize(term, path) when is_bitstring(term), do: error(:unsupported_term, path)

  defp normalize([], _path), do: {:ok, []}
  defp normalize([head | tail], path), do: normalize_list(head, tail, path, 0, [])

  defp normalize(%_{} = _term, path), do: error(:struct_not_allowed, path)

  defp normalize(term, path) when is_map(term) do
    with :ok <- validate_keys(Map.keys(term), path) do
      normalize_map(Map.to_list(term), path, %{})
    end
  end

  defp normalize(term, path) when is_tuple(term), do: error(:tuple_not_allowed, path)

  defp normalize(term, path) when is_pid(term) or is_reference(term) or is_port(term),
    do: error(:runtime_reference_not_allowed, path)

  defp normalize(term, path) when is_function(term), do: error(:unsupported_term, path)
  defp normalize(_term, path), do: error(:unsupported_term, path)

  defp normalize_list(head, tail, path, index, acc) do
    with {:ok, normalized_head} <- normalize(head, [index | path]) do
      case tail do
        [] ->
          {:ok, Enum.reverse([normalized_head | acc])}

        [next | rest] ->
          normalize_list(next, rest, path, index + 1, [normalized_head | acc])

        _improper_tail ->
          error(:improper_list, [index + 1 | path])
      end
    end
  end

  defp validate_keys(keys, path) do
    Enum.reduce_while(keys, :ok, fn key, :ok ->
      cond do
        not is_binary(key) -> {:halt, error(:non_string_key, path)}
        not String.valid?(key) -> {:halt, error(:invalid_utf8, path)}
        true -> {:cont, :ok}
      end
    end)
  end

  defp normalize_map([], _path, acc), do: {:ok, acc}

  defp normalize_map([{key, value} | rest], path, acc) do
    with {:ok, normalized_value} <- normalize(value, [key | path]) do
      normalize_map(rest, path, Map.put(acc, key, normalized_value))
    end
  end

  defp finite?(number), do: number == number and number - number == 0.0

  defp integral_in_safe_range?(number) do
    number >= -@max_safe_integer and number <= @max_safe_integer and number == trunc(number)
  end

  defp error(reason, path) do
    {:error,
     %Error{
       operation: :construct,
       reason: reason,
       path: Pointer.render(path),
       limit: nil,
       actual: nil
     }}
  end
end
