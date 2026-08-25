defmodule Commonplace.Value.DifferentialConformanceTest do
  use ExUnit.Case, async: true

  alias Commonplace.Value

  @differential "conformance/differential"

  test "every differential case matches the bytes recorded from commonplace-log JCS" do
    assert {:ok, cases} = differential_cases(@differential)

    disagreements = Enum.reject(cases, &matches_recorded_bytes?/1)
    assert disagreements == []
  end

  @tag :tmp_dir
  test "the differential harness refuses to report green on an empty directory", %{
    tmp_dir: tmp_dir
  } do
    assert differential_cases(tmp_dir) == {:error, :empty_corpus}
  end

  test "the differential harness checks at least twelve cases" do
    assert {:ok, cases} = differential_cases(@differential)
    assert length(cases) == 12
    assert length(cases) >= 12
  end

  defp differential_cases(root) do
    cases = root |> Path.join("*/") |> Path.wildcard() |> Enum.sort()
    if cases == [], do: {:error, :empty_corpus}, else: {:ok, cases}
  end

  defp matches_recorded_bytes?(directory) do
    input = directory |> Path.join("input.json") |> File.read!() |> String.trim_trailing("\n")
    expected = directory |> Path.join("expected.hex") |> File.read!() |> decode_hex!()
    assert {:ok, value} = Value.from_canonical_json(input)
    Value.encode(value) == expected
  end

  defp decode_hex!(hex), do: hex |> String.trim() |> Base.decode16!(case: :lower)
end
