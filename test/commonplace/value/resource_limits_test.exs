defmodule Commonplace.Value.ResourceLimitsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Commonplace.Value.Domain
  alias Commonplace.Value.Error
  alias Commonplace.Value.Limits
  alias Commonplace.ValueGenerators

  @family "👨‍👩‍👧‍👦"

  test "domain counts the top level scalar as depth zero" do
    assert {:ok, nil} = Domain.validate(nil, limits: limits(max_depth: 1))
  end

  test "domain accepts nesting at exactly max_depth" do
    limits = limits(max_depth: 3)

    assert {:ok, _term_one_below} = Domain.validate(nested_list(2), limits: limits)
    assert {:ok, _term_at_limit} = Domain.validate(nested_list(3), limits: limits)
  end

  test "domain rejects nesting one level beyond max_depth with :max_depth_exceeded" do
    assert_limit_error(
      Domain.validate(nested_list(4), limits: limits(max_depth: 3)),
      :max_depth_exceeded,
      "/0/0/0/0",
      3,
      4
    )
  end

  test "domain checks depth before walking a term deep enough to exhaust the stack" do
    term = nested_list(150_000)

    assert {:error, %Error{reason: :max_depth_exceeded, limit: 64, actual: 65}} =
             Domain.validate(term)
  end

  test "domain accepts a term with exactly max_nodes nodes" do
    limits = limits(max_nodes: 5)

    assert {:ok, _one_below} = Domain.validate(%{"a" => [nil, true]}, limits: limits)
    assert {:ok, _at_limit} = Domain.validate(%{"a" => [nil, true], "b" => %{}}, limits: limits)
  end

  test "domain rejects a term with one node beyond max_nodes" do
    term = List.duplicate(nil, 6)

    assert_limit_error(
      Domain.validate(term, limits: limits(max_nodes: 6)),
      :max_nodes_exceeded,
      "/5",
      6,
      7
    )
  end

  test "domain node count matches an independent recount of the same term" do
    term = %{"array" => [nil, %{"nested" => true}], "scalar" => 7}
    independent_count = independent_node_count(term)

    assert independent_count == 6

    assert {:ok, _normalized} =
             Domain.validate(term, limits: limits(max_nodes: independent_count))

    assert {:error, %Error{reason: :max_nodes_exceeded, actual: ^independent_count}} =
             Domain.validate(term, limits: limits(max_nodes: independent_count - 1))
  end

  test "object keys do not add a second node to their member values" do
    term = %{"key" => 1}

    assert independent_node_count(term) == 2
    assert {:ok, ^term} = Domain.validate(term, limits: limits(max_nodes: 2))

    assert {:error, %Error{reason: :max_nodes_exceeded, limit: 1, actual: 2}} =
             Domain.validate(term, limits: limits(max_nodes: 1))
  end

  test "domain accepts a string of exactly max_string_bytes" do
    limits = limits(max_string_bytes: 25)

    assert {:ok, _one_below} = Domain.validate(String.duplicate("x", 24), limits: limits)
    assert {:ok, @family} = Domain.validate(@family, limits: limits)
  end

  test "domain rejects a string one byte beyond max_string_bytes" do
    assert_limit_error(
      Domain.validate(String.duplicate("x", 26), limits: limits(max_string_bytes: 25)),
      :max_string_bytes_exceeded,
      "",
      25,
      26
    )
  end

  test "domain measures string limits in UTF-8 bytes rather than graphemes" do
    assert String.length(@family) == 1
    assert length(String.codepoints(@family)) == 7
    assert byte_size(@family) == 25

    assert {:error, %Error{reason: :max_string_bytes_exceeded, actual: 25}} =
             Domain.validate(@family, limits: limits(max_string_bytes: 7))
  end

  test "domain applies max_string_bytes to object keys as well as values" do
    key = String.duplicate("key", 4)

    assert_limit_error(
      Domain.validate(%{key => nil}, limits: limits(max_string_bytes: 11)),
      :max_string_bytes_exceeded,
      "/#{key}",
      11,
      12
    )
  end

  test "domain accepts an object with exactly max_object_members" do
    limits = limits(max_object_members: 3)

    assert {:ok, _one_below} = Domain.validate(object(2), limits: limits)
    assert {:ok, _at_limit} = Domain.validate(object(3), limits: limits)
  end

  test "domain rejects an object with one member beyond max_object_members" do
    assert_limit_error(
      Domain.validate(%{"outer" => object(4)}, limits: limits(max_object_members: 3)),
      :max_object_members_exceeded,
      "/outer",
      3,
      4
    )
  end

  test "domain accepts an array with exactly max_array_elements" do
    limits = limits(max_array_elements: 3)

    assert {:ok, _one_below} = Domain.validate(List.duplicate(nil, 2), limits: limits)
    assert {:ok, _at_limit} = Domain.validate(List.duplicate(nil, 3), limits: limits)
  end

  test "domain rejects an array with one element beyond max_array_elements" do
    assert_limit_error(
      Domain.validate(%{"outer" => List.duplicate(nil, 4)},
        limits: limits(max_array_elements: 3)
      ),
      :max_array_elements_exceeded,
      "/outer",
      3,
      4
    )
  end

  test "limit errors report both the limit and the actual value" do
    assert {:error, %Error{limit: 8, actual: 9}} =
             Domain.validate(String.duplicate("x", 9), limits: limits(max_string_bytes: 8))
  end

  test "limit errors report the JSON Pointer path of the offending container" do
    assert_limit_error(
      Domain.validate(%{"nested" => %{"items" => [1, 2, 3]}},
        limits: limits(max_array_elements: 2)
      ),
      :max_array_elements_exceeded,
      "/nested/items",
      2,
      3
    )
  end

  test "limit errors do not reproduce the rejected value" do
    secret = "DISTINCTIVE-LIMIT-SECRET-2f6fc120"

    assert {:error, %Error{} = error} =
             Domain.validate([secret], limits: limits(max_string_bytes: byte_size(secret) - 1))

    refute secret in Map.values(error)
    refute Exception.message(error) =~ secret
    refute inspect(error) =~ secret
  end

  test "domain honours a stricter caller supplied limit set" do
    assert {:error, %Error{reason: :max_string_bytes_exceeded, limit: 2, actual: 3}} =
             Domain.validate("abc", limits: limits(max_string_bytes: 2))
  end

  test "domain honours an explicitly larger finite caller supplied limit set" do
    string = String.duplicate("x", %Limits{}.max_string_bytes + 1)
    larger = limits(max_string_bytes: byte_size(string))

    assert {:ok, ^string} = Domain.validate(string, limits: larger)
  end

  test "property every generated portable term within limits is accepted" do
    check all(term <- ValueGenerators.portable_term(), max_runs: 50) do
      generous =
        limits(
          max_depth: 4,
          max_nodes: 50,
          max_string_bytes: 32,
          max_object_members: 5,
          max_array_elements: 5
        )

      assert {:ok, _normalized} = Domain.validate(term, limits: generous)
    end
  end

  test "property every generated term exceeding a limit is rejected with that limit reason" do
    check all({term, limits, reason} <- ValueGenerators.exceeding_limit(), max_runs: 75) do
      assert {:error, %Error{reason: ^reason}} = Domain.validate(term, limits: limits)
    end
  end

  defp nested_list(depth), do: Enum.reduce(1..depth, nil, fn _, acc -> [acc] end)

  defp object(size), do: Map.new(1..size, fn index -> {Integer.to_string(index), nil} end)

  # Deliberately plain and independent of Domain's traversal state. Object keys
  # are not terms visited as values, so they do not add nodes under plan §4.
  defp independent_node_count(term) when is_list(term) do
    1 + Enum.reduce(term, 0, fn child, count -> count + independent_node_count(child) end)
  end

  defp independent_node_count(term) when is_map(term) do
    1 + Enum.reduce(term, 0, fn {_key, value}, count -> count + independent_node_count(value) end)
  end

  defp independent_node_count(_scalar), do: 1

  defp limits(overrides), do: struct!(Limits, overrides)

  defp assert_limit_error(result, reason, path, limit, actual) do
    assert {:error,
            %Error{
              operation: :construct,
              reason: ^reason,
              path: ^path,
              limit: ^limit,
              actual: ^actual
            }} = result
  end
end
