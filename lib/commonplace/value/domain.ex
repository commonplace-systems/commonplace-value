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
    limits = Keyword.get(opts, :limits, %Limits{})

    with :ok <- validate_limits(limits),
         {:ok, normalized, _nodes} <- normalize(term, [], 0, limits, 0) do
      {:ok, normalized}
    end
  end

  defp validate_limits(limits) do
    case Limits.validate(limits) do
      :ok -> :ok
      {:error, :invalid_limits} -> error(:invalid_limits, [])
    end
  end

  defp normalize(term, path, depth, limits, nodes) do
    with :ok <- check_depth(depth, path, limits),
         {:ok, nodes} <- count_node(nodes, path, limits) do
      normalize_term(term, path, depth, limits, nodes)
    end
  end

  defp normalize_term(nil, _path, _depth, _limits, nodes), do: {:ok, nil, nodes}
  defp normalize_term(true, _path, _depth, _limits, nodes), do: {:ok, true, nodes}
  defp normalize_term(false, _path, _depth, _limits, nodes), do: {:ok, false, nodes}

  defp normalize_term(term, path, _depth, _limits, _nodes) when is_atom(term),
    do: error(:atom_not_allowed, path)

  defp normalize_term(term, _path, _depth, _limits, nodes)
       when is_integer(term) and term >= -@max_safe_integer and term <= @max_safe_integer,
       do: {:ok, term, nodes}

  defp normalize_term(term, path, _depth, _limits, _nodes) when is_integer(term),
    do: error(:integer_out_of_range, path)

  defp normalize_term(term, path, _depth, _limits, nodes) when is_float(term) do
    cond do
      not finite?(term) ->
        error(:non_finite_number, path)

      term == 0.0 ->
        {:ok, 0, nodes}

      integral_in_safe_range?(term) ->
        {:ok, trunc(term), nodes}

      true ->
        {:ok, term, nodes}
    end
  end

  defp normalize_term(term, path, _depth, limits, nodes) when is_binary(term) do
    cond do
      not String.valid?(term) ->
        error(:invalid_utf8, path)

      byte_size(term) > limits.max_string_bytes ->
        limit_error(
          :max_string_bytes_exceeded,
          path,
          limits.max_string_bytes,
          byte_size(term)
        )

      true ->
        {:ok, term, nodes}
    end
  end

  defp normalize_term(term, path, _depth, _limits, _nodes) when is_bitstring(term),
    do: error(:unsupported_term, path)

  defp normalize_term([], path, _depth, limits, nodes) do
    with :ok <- check_array_size([], path, limits) do
      {:ok, [], nodes}
    end
  end

  defp normalize_term([_head | _tail] = term, path, depth, limits, nodes) do
    with :ok <- check_array_size(term, path, limits) do
      normalize_list(term, path, depth + 1, limits, nodes, 0, [])
    end
  end

  defp normalize_term(%_{} = _term, path, _depth, _limits, _nodes),
    do: error(:struct_not_allowed, path)

  defp normalize_term(term, path, depth, limits, nodes) when is_map(term) do
    with :ok <- check_object_size(term, path, limits) do
      normalize_map(Map.to_list(term), path, depth + 1, limits, nodes, %{})
    end
  end

  defp normalize_term(term, path, _depth, _limits, _nodes) when is_tuple(term),
    do: error(:tuple_not_allowed, path)

  defp normalize_term(term, path, _depth, _limits, _nodes)
       when is_pid(term) or is_reference(term) or is_port(term),
       do: error(:runtime_reference_not_allowed, path)

  defp normalize_term(term, path, _depth, _limits, _nodes) when is_function(term),
    do: error(:unsupported_term, path)

  defp normalize_term(_term, path, _depth, _limits, _nodes), do: error(:unsupported_term, path)

  defp normalize_list([], _path, _depth, _limits, nodes, _index, acc) do
    {:ok, Enum.reverse(acc), nodes}
  end

  defp normalize_list([head | tail], path, depth, limits, nodes, index, acc) do
    with {:ok, normalized_head, nodes} <- normalize(head, [index | path], depth, limits, nodes) do
      normalize_list(tail, path, depth, limits, nodes, index + 1, [normalized_head | acc])
    end
  end

  defp normalize_map([], _path, _depth, _limits, nodes, acc), do: {:ok, acc, nodes}

  defp normalize_map([{key, value} | rest], path, depth, limits, nodes, acc) do
    with :ok <- validate_key(key, path, limits),
         {:ok, normalized_value, nodes} <- normalize(value, [key | path], depth, limits, nodes) do
      normalize_map(rest, path, depth, limits, nodes, Map.put(acc, key, normalized_value))
    end
  end

  defp validate_key(key, path, limits) do
    cond do
      not is_binary(key) ->
        error(:non_string_key, path)

      not String.valid?(key) ->
        error(:invalid_utf8, path)

      byte_size(key) > limits.max_string_bytes ->
        limit_error(
          :max_string_bytes_exceeded,
          [key | path],
          limits.max_string_bytes,
          byte_size(key)
        )

      true ->
        :ok
    end
  end

  defp check_depth(depth, path, limits) do
    if depth > limits.max_depth do
      limit_error(:max_depth_exceeded, path, limits.max_depth, depth)
    else
      :ok
    end
  end

  defp count_node(nodes, path, limits) do
    actual = nodes + 1

    if actual > limits.max_nodes do
      limit_error(:max_nodes_exceeded, path, limits.max_nodes, actual)
    else
      {:ok, actual}
    end
  end

  defp check_array_size(term, path, limits) do
    case bounded_list_size(term, limits.max_array_elements, 0) do
      {:ok, _actual} ->
        :ok

      {:limit, actual} ->
        limit_error(:max_array_elements_exceeded, path, limits.max_array_elements, actual)

      {:improper, index} ->
        error(:improper_list, [index | path])
    end
  end

  defp bounded_list_size([], _limit, actual), do: {:ok, actual}

  defp bounded_list_size([_head | _tail], limit, actual) when actual == limit,
    do: {:limit, actual + 1}

  defp bounded_list_size([_head | tail], limit, actual),
    do: bounded_list_size(tail, limit, actual + 1)

  defp bounded_list_size(_improper_tail, _limit, actual), do: {:improper, actual}

  defp check_object_size(term, path, limits) do
    actual = map_size(term)

    if actual > limits.max_object_members do
      limit_error(:max_object_members_exceeded, path, limits.max_object_members, actual)
    else
      :ok
    end
  end

  defp finite?(number), do: number == number and number - number == 0.0

  defp integral_in_safe_range?(number) do
    number >= -@max_safe_integer and number <= @max_safe_integer and number == trunc(number)
  end

  defp error(reason, path), do: error(reason, path, nil, nil)

  defp limit_error(reason, path, limit, actual), do: error(reason, path, limit, actual)

  defp error(reason, path, limit, actual) do
    {:error,
     %Error{
       operation: :construct,
       reason: reason,
       path: Pointer.render(path),
       limit: limit,
       actual: actual
     }}
  end
end
