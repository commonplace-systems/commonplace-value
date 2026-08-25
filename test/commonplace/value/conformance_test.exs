defmodule Commonplace.Value.ConformanceTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Commonplace.Value
  alias Commonplace.ValueGenerators

  @canonical "conformance/canonical"
  @valid_values "conformance/valid-values"

  test "conformance every canonical case encodes to its expected bytes" do
    assert {:ok, cases} = matching_cases(@canonical)
    assert length(cases) == 18
    assert Enum.all?(cases, &matches?/1)
  end

  test "conformance every valid values case encodes to its expected bytes" do
    assert {:ok, cases} = matching_cases(@valid_values)
    assert length(cases) == 9
    assert Enum.all?(cases, &matches?/1)
  end

  test "conformance the deliberate mismatch cases are detected as mismatches" do
    assert {:ok, canonical_mismatches} = mismatch_cases(@canonical)
    assert {:ok, valid_value_mismatches} = mismatch_cases(@valid_values)
    mismatches = canonical_mismatches ++ valid_value_mismatches
    assert length(mismatches) == 2
    assert Enum.all?(mismatches, &(not matches?(&1)))
  end

  @tag :tmp_dir
  test "conformance harness refuses to report green on an empty corpus directory", %{
    tmp_dir: tmp_dir
  } do
    assert matching_cases(tmp_dir) == {:error, :empty_corpus}
  end

  test "conformance harness checks at least twenty nine cases" do
    assert {:ok, canonical} = scan_cases(case_directories(@canonical))
    assert {:ok, valid_values} = scan_cases(case_directories(@valid_values))
    assert length(canonical) == 19
    assert length(valid_values) == 10
    assert length(canonical ++ valid_values) >= 29
  end

  test "property canonical bytes are identical across repeated construction" do
    check all(term <- ValueGenerators.portable_term(), max_runs: 75) do
      assert {:ok, first} = Value.new(term)
      assert {:ok, second} = Value.new(term)
      assert Value.encode(first) == Value.encode(second)
    end
  end

  defp matching_cases(root) do
    with {:ok, cases} <- root |> case_directories() |> scan_cases() do
      {:ok, Enum.reject(cases, &mismatch_case?/1)}
    end
  end

  defp mismatch_cases(root) do
    with {:ok, cases} <- root |> case_directories() |> scan_cases() do
      {:ok, Enum.filter(cases, &mismatch_case?/1)}
    end
  end

  defp case_directories(root), do: root |> Path.join("*/") |> Path.wildcard() |> Enum.sort()

  defp mismatch_case?(directory) do
    directory |> Path.basename() |> String.starts_with?("9")
  end

  defp scan_cases([]), do: {:error, :empty_corpus}
  defp scan_cases(cases), do: {:ok, cases}

  defp matches?(directory) do
    input = File.read!(Path.join(directory, "input.json"))
    expected = directory |> Path.join("expected.hex") |> File.read!() |> decode_hex!()
    assert {:ok, term} = JSON.decode(input)
    assert {:ok, value} = Value.new(term)
    Value.encode(value) == expected
  end

  defp decode_hex!(hex) do
    hex |> String.trim() |> Base.decode16!(case: :lower)
  end
end
