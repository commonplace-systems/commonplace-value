defmodule Commonplace.Value.Composer do
  @moduledoc false

  alias Commonplace.Value
  alias Commonplace.Value.{Domain, Encoder, Error, Limits, Metrics, Pointer}

  @spec compose(Value.composable_term(), keyword()) :: {:ok, Value.t()} | {:error, Error.t()}
  def compose(term, opts) do
    limits = Keyword.get(opts, :limits, %Limits{})

    with :ok <- validate_limits(limits),
         {:ok, normalized, fragment, metrics} <-
           walk(term, [], 0, limits, Metrics.empty()),
         :ok <- check_max_bytes(metrics.encoded_byte_length, limits) do
      canonical_bytes = Encoder.finalize(fragment)

      if byte_size(canonical_bytes) == metrics.encoded_byte_length do
        {:ok,
         %Value{
           canonical_bytes: canonical_bytes,
           normalized_term: normalized,
           metrics: metrics
         }}
      else
        error(:malformed_composition, [])
      end
    end
  end

  defp walk(%Value{} = value, path, depth, limits, metrics) do
    with {:ok, child_metrics, normalized, bytes} <- checked_parts(value, path),
         :ok <- check_depth(depth + child_metrics.maximum_internal_depth, path, limits),
         {:ok, metrics} <- incorporate_child(metrics, child_metrics, depth, path, limits) do
      {:ok, normalized, bytes, metrics}
    end
  end

  defp walk([], path, depth, limits, metrics) do
    with :ok <- check_depth(depth, path, limits),
         {:ok, metrics} <- count_nodes(metrics, 1, path, limits),
         {fragment, overhead} = Encoder.array_fragment_with_overhead([]),
         metrics = add_encoded_bytes(metrics, overhead) do
      metrics = update_container_metrics(metrics, depth, :array, 0)
      {:ok, [], fragment, metrics}
    end
  end

  defp walk([_head | _tail] = term, path, depth, limits, metrics) do
    with :ok <- check_depth(depth, path, limits),
         {:ok, size} <- bounded_list_size(term, path, limits),
         {:ok, metrics} <- count_nodes(metrics, 1, path, limits),
         metrics = update_container_metrics(metrics, depth, :array, size),
         {:ok, normalized, fragments, metrics} <-
           walk_list(term, path, depth + 1, limits, metrics, 0, [], []),
         {fragment, overhead} = Encoder.array_fragment_with_overhead(fragments),
         metrics = add_encoded_bytes(metrics, overhead) do
      {:ok, normalized, fragment, metrics}
    end
  end

  defp walk(%_{} = term, path, depth, limits, metrics) do
    walk_scalar(term, path, depth, limits, metrics)
  end

  defp walk(term, path, depth, limits, metrics) when is_map(term) do
    with :ok <- check_depth(depth, path, limits),
         :ok <- check_object_size(term, path, limits),
         {:ok, metrics} <- count_nodes(metrics, 1, path, limits),
         metrics = update_container_metrics(metrics, depth, :object, map_size(term)),
         {:ok, normalized, fragments, metrics} <-
           walk_map(Map.to_list(term), path, depth + 1, limits, metrics, %{}, []),
         {fragment, overhead} = Encoder.object_fragment_with_overhead(fragments),
         metrics = add_encoded_bytes(metrics, overhead) do
      {:ok, normalized, fragment, metrics}
    end
  end

  defp walk(term, path, depth, limits, metrics) do
    walk_scalar(term, path, depth, limits, metrics)
  end

  defp walk_scalar(term, path, depth, limits, metrics) do
    with :ok <- check_depth(depth, path, limits),
         {:ok, normalized, scalar_metrics} <- validate_scalar(term, path, limits),
         {:ok, metrics} <- count_nodes(metrics, 1, path, limits) do
      metrics = %{
        metrics
        | maximum_internal_depth: max(metrics.maximum_internal_depth, depth),
          maximum_string_byte_length:
            max(
              metrics.maximum_string_byte_length,
              scalar_metrics.maximum_string_byte_length
            )
      }

      {fragment, encoded_byte_length} = Encoder.scalar_fragment_with_length(normalized)
      metrics = add_encoded_bytes(metrics, encoded_byte_length)
      {:ok, normalized, fragment, metrics}
    end
  end

  defp validate_scalar(term, path, limits) do
    case Domain.validate(term, limits: limits) do
      {:ok, normalized, metrics} ->
        {:ok, normalized, metrics}

      {:error, %Error{} = error} ->
        {:error, %{error | path: Pointer.render(path)}}
    end
  end

  defp walk_list([], _path, _depth, _limits, metrics, _index, normalized, fragments) do
    {:ok, Enum.reverse(normalized), Enum.reverse(fragments), metrics}
  end

  defp walk_list(
         [head | tail],
         path,
         depth,
         limits,
         metrics,
         index,
         normalized,
         fragments
       ) do
    with {:ok, normalized_head, fragment, metrics} <-
           walk(head, [index | path], depth, limits, metrics) do
      walk_list(
        tail,
        path,
        depth,
        limits,
        metrics,
        index + 1,
        [normalized_head | normalized],
        [fragment | fragments]
      )
    end
  end

  defp walk_map([], _path, _depth, _limits, metrics, normalized, fragments) do
    {:ok, normalized, Enum.reverse(fragments), metrics}
  end

  defp walk_map([{key, value} | rest], path, depth, limits, metrics, normalized, fragments) do
    with {:ok, key_bytes} <- Domain.validate_composition_key(key, path, limits),
         metrics = %{
           metrics
           | maximum_string_byte_length: max(metrics.maximum_string_byte_length, key_bytes)
         },
         {:ok, normalized_value, fragment, metrics} <-
           walk(value, [key | path], depth, limits, metrics) do
      walk_map(
        rest,
        path,
        depth,
        limits,
        metrics,
        Map.put(normalized, key, normalized_value),
        [{key, fragment} | fragments]
      )
    end
  end

  defp checked_parts(
         %Value{
           canonical_bytes: bytes,
           normalized_term: normalized,
           metrics: %Metrics{} = metrics
         },
         path
       )
       when is_binary(bytes) do
    if valid_metrics?(metrics) and metrics.encoded_byte_length == byte_size(bytes) do
      {:ok, metrics, normalized, bytes}
    else
      malformed_value(path)
    end
  end

  defp checked_parts(_value, path), do: malformed_value(path)

  defp valid_metrics?(%Metrics{} = metrics) do
    metrics.representation_version == 1 and
      positive_integer?(metrics.node_count) and
      non_negative_integer?(metrics.encoded_byte_length) and
      non_negative_integer?(metrics.maximum_internal_depth) and
      non_negative_integer?(metrics.maximum_string_byte_length) and
      non_negative_integer?(metrics.maximum_object_member_count) and
      non_negative_integer?(metrics.maximum_array_element_count)
  end

  defp incorporate_child(metrics, child, depth, path, limits) do
    with {:ok, metrics} <- count_nodes(metrics, child.node_count, path, limits),
         :ok <-
           check_cached_limit(
             child.maximum_string_byte_length,
             limits.max_string_bytes,
             :max_string_bytes_exceeded,
             path
           ),
         :ok <-
           check_cached_limit(
             child.maximum_object_member_count,
             limits.max_object_members,
             :max_object_members_exceeded,
             path
           ),
         :ok <-
           check_cached_limit(
             child.maximum_array_element_count,
             limits.max_array_elements,
             :max_array_elements_exceeded,
             path
           ) do
      {:ok,
       %{
         metrics
         | encoded_byte_length: metrics.encoded_byte_length + child.encoded_byte_length,
           maximum_internal_depth:
             max(metrics.maximum_internal_depth, depth + child.maximum_internal_depth),
           maximum_string_byte_length:
             max(metrics.maximum_string_byte_length, child.maximum_string_byte_length),
           maximum_object_member_count:
             max(metrics.maximum_object_member_count, child.maximum_object_member_count),
           maximum_array_element_count:
             max(metrics.maximum_array_element_count, child.maximum_array_element_count)
       }}
    end
  end

  defp update_container_metrics(metrics, depth, kind, size) do
    metrics = %{metrics | maximum_internal_depth: max(metrics.maximum_internal_depth, depth)}

    case kind do
      :array ->
        %{metrics | maximum_array_element_count: max(metrics.maximum_array_element_count, size)}

      :object ->
        %{metrics | maximum_object_member_count: max(metrics.maximum_object_member_count, size)}
    end
  end

  defp bounded_list_size(term, path, limits) do
    case bounded_list_length(term, limits.max_array_elements, 0) do
      {:ok, size} ->
        {:ok, size}

      {:limit, actual} ->
        limit_error(:max_array_elements_exceeded, path, limits.max_array_elements, actual)

      {:improper, index} ->
        error(:improper_list, [index | path])
    end
  end

  defp bounded_list_length([], _limit, actual), do: {:ok, actual}

  defp bounded_list_length([_head | _tail], limit, actual) when actual == limit,
    do: {:limit, actual + 1}

  defp bounded_list_length([_head | tail], limit, actual),
    do: bounded_list_length(tail, limit, actual + 1)

  defp bounded_list_length(_tail, _limit, actual), do: {:improper, actual}

  defp check_object_size(term, path, limits) do
    actual = map_size(term)

    if actual > limits.max_object_members do
      limit_error(:max_object_members_exceeded, path, limits.max_object_members, actual)
    else
      :ok
    end
  end

  defp check_depth(actual, path, limits) do
    check_cached_limit(actual, limits.max_depth, :max_depth_exceeded, path)
  end

  defp check_cached_limit(actual, limit, reason, path) do
    if actual > limit, do: limit_error(reason, path, limit, actual), else: :ok
  end

  defp count_nodes(metrics, increment, path, limits) do
    actual = metrics.node_count + increment

    if actual > limits.max_nodes do
      limit_error(:max_nodes_exceeded, path, limits.max_nodes, actual)
    else
      {:ok, %{metrics | node_count: actual}}
    end
  end

  defp add_encoded_bytes(metrics, increment) do
    %{metrics | encoded_byte_length: metrics.encoded_byte_length + increment}
  end

  defp check_max_bytes(actual, limits) do
    if actual > limits.max_bytes do
      limit_error(:max_bytes_exceeded, [], limits.max_bytes, actual)
    else
      :ok
    end
  end

  defp validate_limits(limits) do
    case Limits.validate(limits) do
      :ok -> :ok
      {:error, :invalid_limits} -> error(:invalid_limits, [])
    end
  end

  defp malformed_value(path), do: error(:malformed_value_representation, path)
  defp positive_integer?(value), do: is_integer(value) and value > 0
  defp non_negative_integer?(value), do: is_integer(value) and value >= 0

  defp limit_error(reason, path, limit, actual), do: error(reason, path, limit, actual)
  defp error(reason, path), do: error(reason, path, nil, nil)

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
