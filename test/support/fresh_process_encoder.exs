alias Commonplace.Value

:ok = :io.setopts(:standard_io, encoding: :latin1)

case System.argv() do
  ["single"] ->
    {:ok, value} =
      Value.new(%{
        "astral" => <<0x1F600::utf8>>,
        "nested" => [%{"b" => 2, "a" => 1}],
        "n" => 1.0
      })

    IO.binwrite(Value.encode(value))

  ["positive-corpus"] ->
    ["conformance/canonical", "conformance/valid-values"]
    |> Enum.flat_map(fn root -> root |> Path.join("*/") |> Path.wildcard() |> Enum.sort() end)
    |> Enum.each(fn directory ->
      input = File.read!(Path.join(directory, "input.json"))
      {:ok, term} = JSON.decode(input)
      {:ok, value} = Value.new(term)
      bytes = Value.encode(value)
      IO.binwrite(<<byte_size(bytes)::unsigned-big-integer-size(32), bytes::binary>>)
    end)

  arguments ->
    raise ArgumentError, "expected one encoder mode, got: #{inspect(arguments)}"
end
