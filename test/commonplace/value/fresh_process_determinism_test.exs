defmodule Commonplace.Value.FreshProcessDeterminismTest do
  use ExUnit.Case, async: false

  alias Commonplace.Value

  @project_root Path.expand("../../..", __DIR__)
  @script "test/support/fresh_process_encoder.exs"

  test "canonical bytes are identical when produced by a fresh operating system process" do
    term = %{
      "astral" => <<0x1F600::utf8>>,
      "nested" => [%{"b" => 2, "a" => 1}],
      "n" => 1.0
    }

    assert {:ok, value} = Value.new(term)

    assert fresh_process_bytes("single") == Value.encode(value)
  end

  test "the whole positive corpus encodes identically in a fresh operating system process" do
    child = fresh_process_bytes("positive-corpus")
    parent = positive_corpus_bytes()

    assert child == parent,
           "fresh process differed at byte #{first_difference(child, parent)} " <>
             "(child bytes #{byte_size(child)}, parent bytes #{byte_size(parent)})"
  end

  defp fresh_process_bytes(mode) do
    {bytes, status} =
      System.cmd(
        "mix",
        ["run", "--no-compile", "--no-deps-check", @script, mode],
        cd: @project_root,
        env: [{"MIX_ENV", "test"}]
      )

    assert status == 0
    bytes
  end

  defp positive_corpus_bytes do
    ["conformance/canonical", "conformance/valid-values"]
    |> Enum.flat_map(fn root -> root |> Path.join("*/") |> Path.wildcard() |> Enum.sort() end)
    |> Enum.map(fn directory ->
      input = File.read!(Path.join(directory, "input.json"))
      assert {:ok, term} = JSON.decode(input)
      assert {:ok, value} = Value.new(term)
      bytes = Value.encode(value)
      <<byte_size(bytes)::unsigned-big-integer-size(32), bytes::binary>>
    end)
    |> IO.iodata_to_binary()
  end

  defp first_difference(left, right) do
    left
    |> :binary.bin_to_list()
    |> Enum.zip(:binary.bin_to_list(right))
    |> Enum.find_index(fn {left_byte, right_byte} -> left_byte != right_byte end)
    |> case do
      nil -> min(byte_size(left), byte_size(right))
      index -> index
    end
  end
end
