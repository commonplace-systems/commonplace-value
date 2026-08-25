defmodule Commonplace.Value.ConformanceCoverageTest do
  use ExUnit.Case, async: true

  alias Commonplace.Value

  @corpora %{
    canonical: "conformance/canonical",
    valid_values: "conformance/valid-values",
    invalid_values: "conformance/invalid-values",
    differential: "conformance/differential"
  }

  test "every conformance directory is scanned by some harness" do
    counts = Map.new(@corpora, fn {name, root} -> {name, scan_through_its_door(name, root)} end)

    assert counts == %{canonical: 19, valid_values: 10, invalid_values: 22, differential: 12}
  end

  test "each deliberate fixture is observed producing the outcome that fails a broken harness" do
    canonical = "conformance/canonical/999-deliberate-mismatch"
    valid = "conformance/valid-values/999-deliberate-mismatch-empty"
    invalid = "conformance/invalid-values/999-deliberate-acceptance"

    refute constructed_bytes(canonical) == expected_bytes(canonical)
    refute constructed_bytes(valid) == expected_bytes(valid)

    assert {:ok, value} =
             invalid |> Path.join("input.bytes") |> File.read!() |> Value.from_canonical_json()

    assert Value.encode(value) == "1"
  end

  defp scan_through_its_door(name, root) when name in [:canonical, :valid_values] do
    directories = case_directories(root)

    Enum.each(directories, fn directory ->
      assert {:ok, term} = directory |> Path.join("input.json") |> File.read!() |> JSON.decode()
      assert {:ok, _value} = Value.new(term)
    end)

    length(directories)
  end

  defp scan_through_its_door(:invalid_values, root) do
    directories = case_directories(root)

    outcomes =
      Enum.map(directories, fn directory ->
        directory |> Path.join("input.bytes") |> File.read!() |> Value.from_canonical_json()
      end)

    assert Enum.count(outcomes, &match?({:error, _error}, &1)) == 21
    assert Enum.count(outcomes, &match?({:ok, _value}, &1)) == 1
    length(directories)
  end

  defp scan_through_its_door(:differential, root) do
    directories = case_directories(root)

    Enum.each(directories, fn directory ->
      assert {:ok, _value} =
               directory
               |> Path.join("input.json")
               |> File.read!()
               |> String.trim_trailing("\n")
               |> Value.from_canonical_json()
    end)

    length(directories)
  end

  defp case_directories(root) do
    directories = root |> Path.join("*/") |> Path.wildcard() |> Enum.sort()
    assert directories != [], "conformance scan searched zero cases under #{root}"
    directories
  end

  defp constructed_bytes(directory) do
    assert {:ok, term} = directory |> Path.join("input.json") |> File.read!() |> JSON.decode()
    assert {:ok, value} = Value.new(term)
    Value.encode(value)
  end

  defp expected_bytes(directory) do
    directory
    |> Path.join("expected.hex")
    |> File.read!()
    |> String.trim()
    |> Base.decode16!(case: :lower)
  end
end
