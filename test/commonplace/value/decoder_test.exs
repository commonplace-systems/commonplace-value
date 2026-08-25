defmodule Commonplace.Value.DecoderTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Commonplace.Value
  alias Commonplace.Value.{Error, Limits}
  alias Commonplace.ValueGenerators

  test "from canonical json accepts the canonical bytes of every positive corpus case" do
    cases = positive_canonical_bytes()
    assert length(cases) == 27

    for bytes <- cases do
      assert {:ok, value} = Value.from_canonical_json(bytes)
      assert Value.encode(value) == bytes
    end
  end

  test "from canonical json rejects insignificant whitespace" do
    assert_decode_reason(" 1", :non_canonical_json)
    assert_decode_reason(~s({"a": 1}), :non_canonical_json)
  end

  test "from canonical json rejects a trailing newline" do
    assert_decode_reason("1\n", :non_canonical_json)
  end

  test "from canonical json rejects a trailing JSON value" do
    assert_decode_reason_in("1 2", [:trailing_data, :non_canonical_json])
  end

  test "from canonical json rejects a byte order mark" do
    assert_decode_reason_in(<<0xEF, 0xBB, 0xBF, ?1>>, [:invalid_json, :non_canonical_json])
  end

  test "from canonical json rejects unsorted object keys" do
    assert_decode_reason(~s({"b":1,"a":2}), :non_canonical_json)
  end

  test "from canonical json rejects duplicate object keys" do
    assert {:ok, %{"a" => 1}} = JSON.decode(~s({"a":1,"a":2}))
    assert_decode_reason(~s({"a":1,"a":2}), :non_canonical_json)
  end

  test "from canonical json rejects duplicate object keys whose values are equal" do
    assert {:ok, %{"a" => 1}} = JSON.decode(~s({"a":1,"a":1}))
    assert_decode_reason(~s({"a":1,"a":1}), :non_canonical_json)
  end

  test "from canonical json rejects alternate string escapes" do
    assert_decode_reason(~s("\\u0041"), :non_canonical_json)
  end

  test "from canonical json rejects an escaped solidus" do
    assert_decode_reason(~s("a\\/b"), :non_canonical_json)
  end

  test "from canonical json rejects uppercase hexadecimal escapes" do
    assert_decode_reason(~s("\\u001F"), :non_canonical_json)
  end

  test "from canonical json rejects noncanonical number spellings" do
    for bytes <- ["1.0", "1e0", "-0", "1E30"] do
      assert_decode_reason(bytes, :non_canonical_json)
    end
  end

  test "from canonical json rejects malformed UTF-8" do
    assert_decode_reason_in(<<34, 0xFF, 34>>, [:invalid_utf8, :invalid_json])
  end

  test "from canonical json rejects empty and truncated input" do
    assert_decode_reason("", :invalid_json)
    assert_decode_reason("{", :invalid_json)
  end

  test "canonical decoding yields an integer for an integral token in the safe range" do
    assert {:ok, value} = Value.from_canonical_json("9007199254740991")
    assert Value.to_term(value) === 9_007_199_254_740_991
  end

  test "canonical decoding yields a float for an integral token outside the safe range" do
    assert {:ok, value} = Value.from_canonical_json("100000000000000000000")
    assert Value.to_term(value) === 1.0e20
  end

  test "canonical decoding rejects a token whose binary64 image spells differently" do
    assert_decode_reason("9007199254740993", :number_not_interoperable)
  end

  test "the unsafe integer reason differs between construction and decoding" do
    assert {:error, %Error{reason: :integer_out_of_range}} = Value.new(9_007_199_254_740_993)

    assert {:error, %Error{reason: :number_not_interoperable}} =
             Value.from_canonical_json("9007199254740993")
  end

  test "canonical decoding measures max bytes on the input bytes" do
    input = File.read!("conformance/canonical/017-whitespace-padded-entry/input.json")
    assert byte_size(input) == 1_048_977
    assert {:ok, term} = JSON.decode(input)
    assert {:ok, _value} = Value.new(term, limits: limits(max_bytes: 327))

    assert {:error, %Error{reason: :max_bytes_exceeded, actual: 1_048_977}} =
             Value.from_canonical_json(input)
  end

  test "canonical decoding checks the byte limit before parsing" do
    bytes = <<0xFF>> <> String.duplicate("x", 8)

    assert {:error, %Error{reason: :max_bytes_exceeded, limit: 8, actual: 9, operation: :decode}} =
             Value.from_canonical_json(bytes, limits: limits(max_bytes: 8))
  end

  test "decode errors carry the decode operation rather than construct" do
    assert {:error, %Error{operation: :decode, reason: :max_string_bytes_exceeded}} =
             Value.from_canonical_json(~s("secret"), limits: limits(max_string_bytes: 5))
  end

  test "decode errors do not reproduce the rejected bytes" do
    rejected = "DISTINCTIVE-REJECTED-SECRET-715e18"
    assert {:error, error} = Value.from_canonical_json(" " <> rejected)
    refute inspect(error) =~ rejected
    refute Exception.message(error) =~ rejected
  end

  test "canonical decode followed by encode returns identical bytes" do
    bytes = ~s({"a":[null,true,1e+21],"z":"text"})
    assert {:ok, value} = Value.from_canonical_json(bytes)
    assert Value.encode(value) == bytes
  end

  test "a decoded value equals the constructed value it came from" do
    term = %{"a" => [1, 2.5], "z" => nil}
    assert {:ok, constructed} = Value.new(term)
    assert {:ok, decoded} = constructed |> Value.encode() |> Value.from_canonical_json()
    assert Value.equal?(constructed, decoded)
  end

  test "to term of a decoded value equals to term of the constructed value" do
    assert {:ok, constructed} = Value.new(%{"number" => 1.0, "zero" => -0.0})
    assert {:ok, decoded} = constructed |> Value.encode() |> Value.from_canonical_json()
    assert Value.to_term(decoded) === Value.to_term(constructed)
  end

  test "property construct encode decode encode is byte identical" do
    check all(term <- ValueGenerators.portable_term(), max_runs: 75) do
      assert {:ok, constructed} = Value.new(term)
      bytes = Value.encode(constructed)
      assert {:ok, decoded} = Value.from_canonical_json(bytes)
      assert Value.encode(decoded) == bytes
    end
  end

  defp assert_decode_reason(bytes, reason) do
    assert {:error, %Error{operation: :decode, reason: ^reason}} =
             Value.from_canonical_json(bytes)
  end

  defp assert_decode_reason_in(bytes, reasons) do
    assert {:error, %Error{operation: :decode, reason: reason}} =
             Value.from_canonical_json(bytes)

    assert reason in reasons
  end

  defp positive_canonical_bytes do
    ["conformance/canonical", "conformance/valid-values"]
    |> Enum.flat_map(&case_directories/1)
    |> Enum.reject(&mismatch_case?/1)
    |> Enum.map(fn directory ->
      directory
      |> Path.join("expected.hex")
      |> File.read!()
      |> String.trim()
      |> Base.decode16!(case: :lower)
    end)
  end

  defp case_directories(root), do: root |> Path.join("*/") |> Path.wildcard() |> Enum.sort()
  defp mismatch_case?(directory), do: directory |> Path.basename() |> String.starts_with?("9")
  defp limits(overrides), do: struct!(Limits, overrides)
end
