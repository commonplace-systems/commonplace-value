defmodule Commonplace.Value.EncoderTest do
  use ExUnit.Case, async: true

  alias Commonplace.Value

  @max_safe_integer 9_007_199_254_740_991

  test "encoder emits UTF-8 with no BOM and no insignificant whitespace" do
    assert encode(%{"é" => true, "a" => nil}) == ~s({"a":null,"é":true})
    refute String.starts_with?(encode("é"), <<0xEF, 0xBB, 0xBF>>)
  end

  test "encoder sorts object keys by UTF-16 code units" do
    astral = <<0x10000::utf8>>
    bmp = <<0xE000::utf8>>

    assert encode(%{bmp => "bmp", astral => "astral"}) ==
             "{\"#{astral}\":\"astral\",\"#{bmp}\":\"bmp\"}"
  end

  test "encoder sorts object keys recursively at every depth" do
    assert encode(%{"z" => %{"z" => 2, "a" => 1}, "a" => 0}) ==
             ~s({"a":0,"z":{"a":1,"z":2}})
  end

  test "encoder preserves array order" do
    assert encode([3, 1, 2, %{"b" => 1, "a" => 2}]) == ~s([3,1,2,{"a":2,"b":1}])
  end

  test "encoder emits the required two character escapes" do
    assert encode(<<8, 9, 10, 12, 13, 34, 92>>) == ~S("\b\t\n\f\r\"\\")
  end

  test "encoder emits remaining C0 controls as lowercase u00xx escapes" do
    assert encode(<<0, 1, 15, 31>>) == ~S("\u0000\u0001\u000f\u001f")
  end

  test "encoder leaves solidus and non control Unicode unescaped" do
    assert encode("/ café 😀") == ~s("/ café 😀")
  end

  test "encoder spells 1e20 in decimal form and 1e21 with an explicit plus" do
    assert encode(1.0e20) == "100000000000000000000"
    assert encode(1.0e21) == "1e+21"
  end

  test "encoder spells 1e-6 in decimal form and 1e-7 in exponential form" do
    assert encode(1.0e-6) == "0.000001"
    assert encode(1.0e-7) == "1e-7"
  end

  test "encoder emits negative zero as 0" do
    assert encode(-0.0) == "0"
  end

  test "encoder emits safe integers without an exponent" do
    assert encode(@max_safe_integer) == "9007199254740991"
    assert encode(-@max_safe_integer) == "-9007199254740991"
  end

  defp encode(term) do
    assert {:ok, value} = Value.new(term)
    Value.encode(value)
  end
end
