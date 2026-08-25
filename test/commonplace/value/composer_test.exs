defmodule Commonplace.Value.ComposerTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Commonplace.Value
  alias Commonplace.Value.{Domain, Encoder, Error, Limits}

  test "compose accepts a scalar existing value as the top level input" do
    assert {:ok, child} = Value.new(1.0)
    assert {:ok, composed} = Value.compose(child)
    assert Value.equal?(composed, child)
    assert Value.to_term(composed) === 1
  end

  test "compose embeds existing values at multiple list and map depths" do
    assert {:ok, child} = Value.new(%{"leaf" => [1, 2]})
    assert {:ok, composed} = Value.compose(%{"outer" => [[%{"child" => child}]]})

    assert Value.to_term(composed) == %{
             "outer" => [[%{"child" => %{"leaf" => [1, 2]}}]]
           }
  end

  test "compose accepts repeated inclusion of the same child value" do
    assert {:ok, child} = Value.new(%{"x" => [1, 2]})
    assert {:ok, composed} = Value.compose([child, child, child])
    assert Value.to_term(composed) == List.duplicate(%{"x" => [1, 2]}, 3)
  end

  test "compose mixes raw portable leaves and constructed value leaves" do
    assert {:ok, child} = Value.new([true, nil])
    assert {:ok, composed} = Value.compose(%{"child" => child, "raw" => [1.0, "text"]})
    assert Value.to_term(composed) === %{"child" => [true, nil], "raw" => [1, "text"]}
  end

  test "compose rejects every non value struct" do
    for struct <- [URI.parse("https://example.test"), %Error{}] do
      assert {:error, %Error{reason: :struct_not_allowed}} = Value.compose(struct)
    end
  end

  test "compose rejects runtime references outside and beside valid value leaves" do
    assert {:ok, child} = Value.new("safe")

    for reference <- [self(), make_ref(), fn -> :ok end] do
      assert {:error, %Error{reason: reason, path: "/bad"}} =
               Value.compose(%{"child" => child, "bad" => reference})

      assert reason in [:runtime_reference_not_allowed, :unsupported_term]
    end

    assert {:error, %Error{reason: :runtime_reference_not_allowed, path: ""}} =
             Value.compose(self())
  end

  test "compose rejects an existing value used as an object key" do
    assert {:ok, child} = Value.new("key")
    assert {:error, %Error{reason: :non_string_key, path: ""}} = Value.compose(%{child => nil})
  end

  test "compose produces canonical bytes equal to fully expanded construction" do
    {mixed, expanded} = mixed_fixture()
    assert {:ok, composed} = Value.compose(mixed)
    assert {:ok, rebuilt} = Value.new(expanded)
    assert Value.encode(composed) == Value.encode(rebuilt)
  end

  test "compose produces a normalized term equal to fully expanded construction" do
    {mixed, expanded} = mixed_fixture()
    assert {:ok, composed} = Value.compose(mixed)
    assert {:ok, rebuilt} = Value.new(expanded)
    assert Value.to_term(composed) === Value.to_term(rebuilt)
    assert Value.equal?(composed, rebuilt)
  end

  test "compose normalizes numbers across a composition boundary" do
    assert {:ok, child} = Value.new(%{"inside" => [1.0, -0.0]})
    assert {:ok, composed} = Value.compose(%{"child" => child, "raw" => [1.0, -0.0]})

    assert Value.to_term(composed) === %{
             "child" => %{"inside" => [1, 0]},
             "raw" => [1, 0]
           }

    assert Value.encode(composed) == ~s({"child":{"inside":[1,0]},"raw":[1,0]})
  end

  test "compose orders newly introduced keys by UTF-16 code units" do
    assert {:ok, child} = Value.new("child")
    assert {:ok, composed} = Value.compose(%{"\u{E000}" => child, "\u{10000}" => 1})

    assert Value.encode(composed) ==
             <<?{, ?\", 0xF0, 0x90, 0x80, 0x80, ?\", ?:, ?1, ?,, ?\", 0xEE, 0x80, 0x80, ?\", ?:,
               ?\", "child", ?\", ?}>>
  end

  test "compose accepts child objects whose own keys are already canonical" do
    assert {:ok, child} = Value.new(%{"z" => 1, "a" => 2})
    assert Value.encode(child) == ~s({"a":2,"z":1})
    assert {:ok, composed} = Value.compose(%{"child" => child})
    assert Value.encode(composed) == ~s({"child":{"a":2,"z":1}})
  end

  test "to term of a composed value contains no nested value structs" do
    assert {:ok, child} = Value.new(%{"nested" => [1]})
    assert {:ok, composed} = Value.compose(%{"one" => [child], "two" => child})
    refute contains_value_struct?(Value.to_term(composed))
  end

  test "compose enforces max bytes on the complete composed result" do
    assert {:ok, child} = Value.new("abc")
    assert {:ok, exact} = Value.compose(%{"x" => child}, limits: limits(max_bytes: 11))
    assert byte_size(Value.encode(exact)) == 11

    assert {:error, %Error{reason: :max_bytes_exceeded, limit: 10, actual: 11}} =
             Value.compose(%{"x" => child}, limits: limits(max_bytes: 10))
  end

  test "compose offsets child depth by its nesting position and enforces max depth" do
    child_term = nested_list(40)
    assert {:ok, child} = Value.new(child_term, limits: limits(max_depth: 100))
    template = Enum.reduce(1..30, child, fn _, acc -> [acc] end)

    assert {:error, %Error{reason: :max_depth_exceeded, limit: 64, actual: 70}} =
             Value.compose(template)

    assert {:ok, empty_child} = Value.new([])
    assert empty_child.metrics.maximum_internal_depth == 0
    nested_empty = Enum.reduce(1..30, empty_child, fn _, acc -> [acc] end)
    assert {:ok, at_limit} = Value.compose(nested_empty, limits: limits(max_depth: 30))
    assert at_limit.metrics.maximum_internal_depth == 30
  end

  test "compose counts nodes exactly including each repeated child occurrence" do
    assert {:ok, child} = Value.new([nil, true])
    assert child.metrics.node_count == 3
    assert {:ok, value} = Value.compose([child, child], limits: limits(max_nodes: 7))
    assert value.metrics.node_count == 7

    assert {:error, %Error{reason: :max_nodes_exceeded, limit: 6, actual: 7}} =
             Value.compose([child, child], limits: limits(max_nodes: 6))
  end

  test "compose enforces maximum string object member and array element limits" do
    assert {:ok, long_string} = Value.new("abcd", limits: limits(max_string_bytes: 4))
    assert {:ok, wide_object} = Value.new(%{"a" => 1, "b" => 2})
    assert {:ok, wide_array} = Value.new([1, 2])

    assert {:error, %Error{reason: :max_string_bytes_exceeded}} =
             Value.compose(long_string, limits: limits(max_string_bytes: 3))

    assert {:error, %Error{reason: :max_object_members_exceeded}} =
             Value.compose(wide_object, limits: limits(max_object_members: 1))

    assert {:error, %Error{reason: :max_array_elements_exceeded}} =
             Value.compose(wide_array, limits: limits(max_array_elements: 1))
  end

  test "compose rejects a child constructed under limits larger than the composing call" do
    assert {:ok, child} = Value.new(nested_list(65), limits: limits(max_depth: 100))

    assert {:error, %Error{reason: :max_depth_exceeded, limit: 64, actual: 65}} =
             Value.compose(child)
  end

  test "compose rejects an obviously malformed value representation through bounded checks" do
    assert {:ok, child} = Value.new(%{"deep" => [1, 2, 3]})
    malformed = %{child | metrics: %{child.metrics | representation_version: 2}}

    assert {:error, %Error{reason: :malformed_value_representation, path: "/child"}} =
             Value.compose(%{"child" => malformed})
  end

  test "a composed value round trips through canonical encode and decode" do
    {mixed, _expanded} = mixed_fixture()
    assert {:ok, composed} = Value.compose(mixed)
    assert {:ok, decoded} = Value.from_canonical_json(Value.encode(composed))
    assert Value.equal?(decoded, composed)
    assert Value.to_term(decoded) === Value.to_term(composed)
  end

  test "a composed value is completely revalidated after crossing a process boundary" do
    {mixed, _expanded} = mixed_fixture()
    assert {:ok, composed} = Value.compose(mixed)
    bytes = Value.encode(composed)
    parent = self()

    spawn(fn -> send(parent, {:decoded, Value.from_canonical_json(bytes)}) end)

    assert_receive {:decoded, {:ok, received}}
    assert Value.equal?(received, composed)
    assert Value.encode(received) == bytes
    assert Value.to_term(received) === Value.to_term(composed)
  end

  test "composing the cell request envelope visits each raw outer node once" do
    {envelope, _expanded} = cell_envelope_fixture()

    patterns = [
      {Domain, :validate, 2},
      {Encoder, :scalar_fragment_with_length, 1},
      {Encoder, :array_fragment_with_overhead, 1},
      {Encoder, :object_fragment_with_overhead, 1},
      {Encoder, :finalize, 1}
    ]

    {_result, calls} = trace_calls(patterns, fn -> Value.compose(envelope) end)

    assert calls[{Domain, :validate, 2}] == raw_scalar_count(envelope)
    assert calls[{Encoder, :scalar_fragment_with_length, 1}] == raw_scalar_count(envelope)
    assert calls[{Encoder, :array_fragment_with_overhead, 1}] == raw_array_count(envelope)
    assert calls[{Encoder, :object_fragment_with_overhead, 1}] == raw_object_count(envelope)
    assert calls[{Encoder, :finalize, 1}] == 1
  end

  test "composing the cell request envelope incorporates children without walking their subtrees" do
    {envelope, _expanded} = cell_envelope_fixture()
    expected_raw_scalars = raw_scalar_count(envelope)

    {_result, calls} = trace_calls([{Domain, :validate, 2}], fn -> Value.compose(envelope) end)

    assert calls[{Domain, :validate, 2}] == expected_raw_scalars
    assert expected_raw_scalars < expanded_scalar_count(envelope)
  end

  test "the composed cell request envelope is byte identical to full reconstruction" do
    {envelope, expanded} = cell_envelope_fixture()
    assert {:ok, composed} = Value.compose(envelope)
    assert {:ok, rebuilt} = Value.new(expanded)
    assert Value.encode(composed) == Value.encode(rebuilt)
  end

  test "property composing a mixed tree equals constructing the expanded tree" do
    check all(
            original <- Commonplace.ValueGenerators.portable_term(),
            selector <- integer(0..7),
            max_runs: 50
          ) do
      {mixed, expanded} = replace_subtrees(original, selector)
      assert {:ok, composed} = Value.compose(mixed)
      assert {:ok, rebuilt} = Value.new(expanded)
      assert Value.encode(composed) == Value.encode(rebuilt)
      assert Value.equal?(composed, rebuilt)
      assert Value.to_term(composed) === Value.to_term(rebuilt)
      assert composed.metrics == rebuilt.metrics
    end
  end

  defp mixed_fixture do
    assert {:ok, object} = Value.new(%{"z" => [1.0, "x"], "a" => true})
    assert {:ok, scalar} = Value.new(-0.0)

    mixed = %{"object" => object, "list" => [scalar, 2.0, %{"raw" => nil}]}
    expanded = %{"object" => Value.to_term(object), "list" => [0, 2, %{"raw" => nil}]}
    {mixed, expanded}
  end

  defp cell_envelope_fixture do
    assert {:ok, target} =
             Value.new(%{"cell_id" => "target-1", "resource" => %{"kind" => "cell"}})

    assert {:ok, arguments} = Value.new(%{"coordinate" => [42, %{"deep" => true}]})
    assert {:ok, proof_one} = Value.new(%{"kind" => "signature", "valid" => true})
    assert {:ok, proof_two} = Value.new([%{"chain" => [1, 2, 3]}])
    assert {:ok, extensions} = Value.new(%{"vendor" => %{"flag" => false}})

    envelope = %{
      "format" => "commonplace.cell.request/v1",
      "request_id" => "request-1",
      "source_cell_id" => "source-1",
      "target" => target,
      "verb" => "cell.describe",
      "arguments" => arguments,
      "proofs" => [proof_one, proof_two],
      "correlation_id" => "correlation-1",
      "causation_id" => "causation-1",
      "extensions" => extensions
    }

    {envelope, expand_values(envelope)}
  end

  defp trace_calls(patterns, fun) do
    parent = self()
    tracer = spawn(fn -> trace_collector(parent, %{}) end)
    :erlang.trace(self(), true, [:call, {:tracer, tracer}])

    Enum.each(patterns, fn pattern ->
      assert :erlang.trace_pattern(pattern, true, []) == 1
    end)

    result = fun.()
    :erlang.trace(self(), false, [:call])
    delivered = :erlang.trace_delivered(self())
    assert_receive {:trace_delivered, _pid, ^delivered}
    send(tracer, {:counts, self()})
    assert_receive {:trace_counts, calls}

    Enum.each(patterns, &:erlang.trace_pattern(&1, false, []))
    {result, calls}
  end

  defp trace_collector(parent, counts) do
    receive do
      {:trace, _pid, :call, {module, function, arguments}} ->
        key = {module, function, length(arguments)}
        trace_collector(parent, Map.update(counts, key, 1, &(&1 + 1)))

      {:counts, reply_to} ->
        send(reply_to, {:trace_counts, counts})
        send(parent, :trace_collector_stopped)
    end
  end

  defp raw_scalar_count(%Value{}), do: 0

  defp raw_scalar_count(term) when is_list(term),
    do: Enum.sum(Enum.map(term, &raw_scalar_count/1))

  defp raw_scalar_count(term) when is_map(term),
    do: Enum.sum(Enum.map(Map.values(term), &raw_scalar_count/1))

  defp raw_scalar_count(_term), do: 1

  defp raw_array_count(%Value{}), do: 0

  defp raw_array_count(term) when is_list(term),
    do: 1 + Enum.sum(Enum.map(term, &raw_array_count/1))

  defp raw_array_count(term) when is_map(term),
    do: Enum.sum(Enum.map(Map.values(term), &raw_array_count/1))

  defp raw_array_count(_term), do: 0

  defp raw_object_count(%Value{}), do: 0

  defp raw_object_count(term) when is_list(term),
    do: Enum.sum(Enum.map(term, &raw_object_count/1))

  defp raw_object_count(term) when is_map(term),
    do: 1 + Enum.sum(Enum.map(Map.values(term), &raw_object_count/1))

  defp raw_object_count(_term), do: 0

  defp expanded_scalar_count(%Value{} = value), do: expanded_scalar_count(Value.to_term(value))

  defp expanded_scalar_count(term) when is_list(term),
    do: Enum.sum(Enum.map(term, &expanded_scalar_count/1))

  defp expanded_scalar_count(term) when is_map(term),
    do: Enum.sum(Enum.map(Map.values(term), &expanded_scalar_count/1))

  defp expanded_scalar_count(_term), do: 1

  defp expand_values(%Value{} = value), do: Value.to_term(value)
  defp expand_values(term) when is_list(term), do: Enum.map(term, &expand_values/1)

  defp expand_values(term) when is_map(term),
    do: Map.new(term, fn {key, value} -> {key, expand_values(value)} end)

  defp expand_values(term), do: term

  defp replace_subtrees(term, selector), do: replace_subtrees(term, selector, 0)

  defp replace_subtrees(term, selector, depth) when depth > 0 and rem(selector + depth, 3) == 0 do
    assert {:ok, value} = Value.new(term)
    {value, Value.to_term(value)}
  end

  defp replace_subtrees(term, selector, depth) when is_list(term) do
    pairs = Enum.map(term, &replace_subtrees(&1, selector, depth + 1))
    {Enum.map(pairs, &elem(&1, 0)), Enum.map(pairs, &elem(&1, 1))}
  end

  defp replace_subtrees(term, selector, depth) when is_map(term) do
    pairs =
      Map.new(term, fn {key, value} -> {key, replace_subtrees(value, selector, depth + 1)} end)

    {Map.new(pairs, fn {key, pair} -> {key, elem(pair, 0)} end),
     Map.new(pairs, fn {key, pair} -> {key, elem(pair, 1)} end)}
  end

  defp replace_subtrees(term, _selector, _depth), do: {term, term}

  defp contains_value_struct?(%Value{}), do: true

  defp contains_value_struct?(term) when is_list(term),
    do: Enum.any?(term, &contains_value_struct?/1)

  defp contains_value_struct?(term) when is_map(term),
    do: Enum.any?(Map.values(term), &contains_value_struct?/1)

  defp contains_value_struct?(_term), do: false

  defp nested_list(depth), do: Enum.reduce(1..depth, nil, fn _, acc -> [acc] end)
  defp limits(overrides), do: struct!(Limits, overrides)
end
