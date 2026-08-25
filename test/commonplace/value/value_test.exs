defmodule Commonplace.ValueTest do
  use ExUnit.Case, async: true

  alias Commonplace.Value
  alias Commonplace.Value.{Error, Limits, Metrics}

  test "new returns an opaque value whose canonical bytes are its identity" do
    assert {:ok, value} = Value.new(%{"b" => 2, "a" => 1})
    assert %Value{} = value
    assert Value.encode(value) == ~s({"a":1,"b":2})
  end

  test "constructed values carry every cached metric the composition ruling requires" do
    term = %{
      "long-key" => ["abc", %{"x" => [nil, true]}],
      "wide" => [1, 2, 3]
    }

    assert {:ok, value} = Value.new(term)
    metrics = Map.fetch!(value, :metrics)

    assert %Metrics{
             node_count: 11,
             maximum_internal_depth: 4,
             maximum_string_byte_length: 8,
             maximum_object_member_count: 2,
             maximum_array_element_count: 3,
             representation_version: 1
           } = metrics

    assert metrics.encoded_byte_length == byte_size(Value.encode(value))
    assert independent_node_count(Value.to_term(value)) == metrics.node_count
  end

  test "cached maximum depth is the value own internal depth not its nesting position" do
    assert {:ok, scalar} = Value.new("leaf")
    assert {:ok, child} = Value.new(%{"items" => [[nil]]})
    assert Map.fetch!(scalar, :metrics).maximum_internal_depth == 0
    assert Map.fetch!(child, :metrics).maximum_internal_depth == 3
  end

  test "inspect shows bounded metadata rather than the entire value" do
    assert {:ok, value} = Value.new(%{"payload" => String.duplicate("x", 1_000)})
    assert inspect(value) == "#Commonplace.Value<bytes: 1014>"
  end

  test "inspect does not reveal a secret contained in the value" do
    secret = "DISTINCTIVE-VALUE-SECRET-9154f06d"
    assert {:ok, value} = Value.new(%{"secret" => secret})
    refute inspect(value) =~ secret
  end

  test "encode returns the canonical bytes of a constructed value" do
    assert {:ok, value} = Value.new(%{"z" => 1, "a" => 2})
    assert Value.encode(value) == ~s({"a":2,"z":1})
  end

  test "to_term returns the normalized term" do
    assert {:ok, value} = Value.new(%{"number" => 1.0, "zero" => -0.0})
    assert Value.to_term(value) === %{"number" => 1, "zero" => 0}
  end

  test "equal? is canonical byte equality" do
    assert {:ok, left} = Value.new(%{"a" => 1})
    assert {:ok, same} = Value.new(%{"a" => 1.0})
    assert {:ok, different} = Value.new(%{"a" => 2})
    altered_bytes = %{left | canonical_bytes: ~s({"a":9})}

    assert Value.equal?(left, same)
    refute Value.equal?(left, different)
    refute Value.equal?(left, altered_bytes)
    assert Value.to_term(left) == Value.to_term(altered_bytes)
  end

  test "new of 1 and new of 1.0 construct equal values" do
    assert {:ok, integer} = Value.new(1)
    assert {:ok, float} = Value.new(1.0)
    assert Value.equal?(integer, float)
  end

  test "new of 0 and new of negative zero construct equal values encoding to 0" do
    assert {:ok, zero} = Value.new(0)
    assert {:ok, negative_zero} = Value.new(-0.0)
    assert Value.equal?(zero, negative_zero)
    assert Value.encode(negative_zero) == "0"
  end

  test "new rejects a Commonplace.Value struct as an ordinary term" do
    assert {:ok, value} = Value.new(nil)

    assert {:error, %Error{reason: :struct_not_allowed, path: ""}} = Value.new(value)
  end

  test "construction accepts a term whose canonical bytes are exactly max_bytes" do
    assert {:ok, value} = Value.new("abc", limits: limits(max_bytes: 5))
    assert Value.encode(value) == ~s("abc")
  end

  test "construction rejects a term whose canonical bytes exceed max_bytes" do
    assert {:error, %Error{reason: :max_bytes_exceeded, path: "", limit: 4, actual: 5}} =
             Value.new("abc", limits: limits(max_bytes: 4))
  end

  test "max_bytes is measured on canonical bytes rather than on the input term" do
    input = File.read!("conformance/canonical/017-whitespace-padded-entry/input.json")
    assert byte_size(input) > %Limits{}.max_bytes
    assert {:ok, term} = JSON.decode(input)
    assert {:ok, value} = Value.new(term, limits: limits(max_bytes: 327))
    assert byte_size(Value.encode(value)) == 327
  end

  defp independent_node_count(term) when is_list(term) do
    1 + Enum.reduce(term, 0, fn child, count -> count + independent_node_count(child) end)
  end

  defp independent_node_count(term) when is_map(term) do
    1 + Enum.reduce(term, 0, fn {_key, value}, count -> count + independent_node_count(value) end)
  end

  defp independent_node_count(_scalar), do: 1

  defp limits(overrides), do: struct!(Limits, overrides)
end
