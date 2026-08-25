defmodule Commonplace.Value.InvalidValuesConformanceTest do
  use ExUnit.Case, async: true

  alias Commonplace.Value

  @invalid_values "conformance/invalid-values"

  test "conformance every invalid values case is rejected with an accepted reason slug" do
    assert {:ok, cases} = rejection_cases(@invalid_values)
    assert length(cases) == 21

    for directory <- cases do
      accepted_reasons = accepted_reasons(directory)
      assert {:error, error} = Value.from_canonical_json(input(directory))
      assert Atom.to_string(error.reason) in accepted_reasons
    end
  end

  test "conformance the deliberate acceptance case is accepted rather than rejected" do
    directory = Path.join(@invalid_values, "999-deliberate-acceptance")
    assert {:ok, value} = directory |> input() |> Value.from_canonical_json()
    assert Value.encode(value) == "1"
  end

  @tag :tmp_dir
  test "conformance invalid values harness refuses to report green on an empty directory", %{
    tmp_dir: tmp_dir
  } do
    assert rejection_cases(tmp_dir) == {:error, :empty_corpus}
  end

  test "conformance invalid values harness checks at least twenty two cases" do
    assert {:ok, cases} = scan_cases(case_directories(@invalid_values))
    assert length(cases) == 22
    assert length(cases) >= 22
  end

  defp rejection_cases(root) do
    with {:ok, cases} <- root |> case_directories() |> scan_cases() do
      {:ok, Enum.reject(cases, &acceptance_case?/1)}
    end
  end

  defp case_directories(root), do: root |> Path.join("*/") |> Path.wildcard() |> Enum.sort()
  defp scan_cases([]), do: {:error, :empty_corpus}
  defp scan_cases(cases), do: {:ok, cases}

  defp acceptance_case?(directory) do
    directory |> Path.basename() |> String.starts_with?("999-")
  end

  defp input(directory), do: File.read!(Path.join(directory, "input.bytes"))

  defp accepted_reasons(directory) do
    directory
    |> Path.join("reason")
    |> File.read!()
    |> String.split("\n", trim: true)
  end
end
