defmodule Commonplace.ValueGenerators do
  import StreamData

  alias Commonplace.Value.Limits

  def portable_term do
    scalar =
      one_of([
        member_of([nil, true, false]),
        integer(-100..100),
        float(min: -100.0, max: 100.0),
        string(:ascii, max_length: 12)
      ])

    object = map_of(string(:ascii, min_length: 1, max_length: 8), scalar, max_length: 4)

    one_of([
      scalar,
      list_of(scalar, max_length: 5),
      object,
      list_of(object, max_length: 3)
    ])
  end

  def exceeding_limit do
    bind({member_of([:depth, :nodes, :string, :object, :array]), integer(1..12)}, fn
      {:depth, limit} ->
        constant({nested_list(limit + 1), limits(max_depth: limit), :max_depth_exceeded})

      {:nodes, limit} ->
        constant({List.duplicate(nil, limit), limits(max_nodes: limit), :max_nodes_exceeded})

      {:string, limit} ->
        constant(
          {String.duplicate("x", limit + 1), limits(max_string_bytes: limit),
           :max_string_bytes_exceeded}
        )

      {:object, limit} ->
        term = Map.new(0..limit, fn index -> {Integer.to_string(index), nil} end)
        constant({term, limits(max_object_members: limit), :max_object_members_exceeded})

      {:array, limit} ->
        constant(
          {List.duplicate(nil, limit + 1), limits(max_array_elements: limit),
           :max_array_elements_exceeded}
        )
    end)
  end

  defp nested_list(depth), do: Enum.reduce(1..depth, nil, fn _, acc -> [acc] end)
  defp limits(overrides), do: struct!(Limits, overrides)
end
