defmodule Commonplace.Value.LimitsTest do
  use ExUnit.Case, async: true

  alias Commonplace.Value.Limits

  # Spec §13, verbatim. §22 makes a change to these bytes a BREAKING change,
  # so the values are asserted individually and by exhaustive field set: a new
  # field added without a decision fails the second assertion even though every
  # existing field still matches.
  #
  # ⭐ Shape equality is not validity — but here the shape IS the contract, and
  # the failure mode this arm exists for is a silent default drift, which an
  # equality assertion does catch.
  test "default limits match the specification table" do
    limits = %Limits{}

    assert limits.max_bytes == 1_048_576
    assert limits.max_depth == 64
    assert limits.max_nodes == 100_000
    assert limits.max_string_bytes == 1_048_576
    assert limits.max_object_members == 100_000
    assert limits.max_array_elements == 100_000

    assert limits |> Map.from_struct() |> Map.keys() |> Enum.sort() == [
             :max_array_elements,
             :max_bytes,
             :max_depth,
             :max_nodes,
             :max_object_members,
             :max_string_bytes
           ]
  end
end
