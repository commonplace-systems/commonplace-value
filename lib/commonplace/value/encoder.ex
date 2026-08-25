defmodule Commonplace.Value.Encoder do
  @moduledoc false

  import Bitwise

  @spec encode(Commonplace.Value.Domain.normalized_term()) :: binary()
  def encode(term), do: term |> encode_term() |> finalize()

  @doc false
  @spec finalize(iodata()) :: binary()
  def finalize(fragment), do: IO.iodata_to_binary(fragment)

  @doc false
  @spec scalar_fragment(nil | boolean() | number() | String.t()) :: iodata()
  def scalar_fragment(term), do: encode_term(term)

  @doc false
  @spec scalar_fragment_with_length(nil | boolean() | number() | String.t()) ::
          {iodata(), non_neg_integer()}
  def scalar_fragment_with_length(term) do
    fragment = scalar_fragment(term)
    {fragment, IO.iodata_length(fragment)}
  end

  @doc false
  @spec array_fragment([iodata()]) :: iodata()
  def array_fragment(fragments), do: [?[, join(fragments), ?]]

  @doc false
  @spec array_fragment_with_overhead([iodata()]) :: {iodata(), pos_integer()}
  def array_fragment_with_overhead(fragments) do
    {array_fragment(fragments), 2 + max(length(fragments) - 1, 0)}
  end

  @doc false
  @spec object_fragment([{String.t(), iodata()}]) :: iodata()
  def object_fragment(members) do
    {fragment, _overhead} = object_fragment_with_overhead(members)
    fragment
  end

  @doc false
  @spec object_fragment_with_overhead([{String.t(), iodata()}]) ::
          {iodata(), pos_integer()}
  def object_fragment_with_overhead(members) do
    encoded_members =
      members
      |> Enum.sort_by(fn {key, _fragment} -> utf16_sort_key(key) end)
      |> Enum.map(fn {key, fragment} ->
        encoded_key = encode_string(key)
        {[?\", encoded_key, ?\", ?:, fragment], IO.iodata_length(encoded_key) + 3}
      end)

    fragments = Enum.map(encoded_members, &elem(&1, 0))
    keys_and_colons = Enum.reduce(encoded_members, 0, fn {_fragment, size}, acc -> acc + size end)
    overhead = 2 + max(length(encoded_members) - 1, 0) + keys_and_colons
    {[?{, join(fragments), ?}], overhead}
  end

  defp encode_term(nil), do: "null"
  defp encode_term(true), do: "true"
  defp encode_term(false), do: "false"
  defp encode_term(term) when is_integer(term), do: Integer.to_string(term)
  defp encode_term(term) when is_float(term), do: encode_float(term)
  defp encode_term(term) when is_binary(term), do: [?\", encode_string(term), ?\"]

  defp encode_term(term) when is_list(term) do
    term |> Enum.map(&encode_term/1) |> array_fragment()
  end

  defp encode_term(term) when is_map(term) do
    term
    |> Enum.map(fn {key, value} -> {key, encode_term(value)} end)
    |> object_fragment()
  end

  defp join([]), do: []
  defp join([item | rest]), do: [item | Enum.map(rest, &[?,, &1])]

  defp utf16_sort_key(string) do
    :unicode.characters_to_binary(string, :utf8, {:utf16, :big})
  end

  defp encode_string(string), do: encode_string(string, [])

  defp encode_string(<<>>, acc), do: Enum.reverse(acc)
  defp encode_string(<<?\b, rest::binary>>, acc), do: encode_string(rest, ["\\b" | acc])
  defp encode_string(<<?\t, rest::binary>>, acc), do: encode_string(rest, ["\\t" | acc])
  defp encode_string(<<?\n, rest::binary>>, acc), do: encode_string(rest, ["\\n" | acc])
  defp encode_string(<<?\f, rest::binary>>, acc), do: encode_string(rest, ["\\f" | acc])
  defp encode_string(<<?\r, rest::binary>>, acc), do: encode_string(rest, ["\\r" | acc])
  defp encode_string(<<?\", rest::binary>>, acc), do: encode_string(rest, ["\\\"" | acc])
  defp encode_string(<<?\\, rest::binary>>, acc), do: encode_string(rest, ["\\\\" | acc])

  defp encode_string(<<control, rest::binary>>, acc) when control < 0x20 do
    escape = ["\\u00", hex_digit(control >>> 4), hex_digit(control &&& 0x0F)]
    encode_string(rest, [escape | acc])
  end

  defp encode_string(<<codepoint::utf8, rest::binary>>, acc) do
    encode_string(rest, [<<codepoint::utf8>> | acc])
  end

  defp hex_digit(value) when value < 10, do: ?0 + value
  defp hex_digit(value), do: ?a + value - 10

  defp encode_float(number) do
    number
    |> :erlang.float_to_binary([:short])
    |> split_short_float()
    |> layout_float()
  end

  defp split_short_float(short) do
    {sign, unsigned} =
      case short do
        <<?-, rest::binary>> -> {"-", rest}
        _other -> {"", short}
      end

    {mantissa, exponent} =
      case :binary.split(unsigned, "e") do
        [plain] -> {plain, 0}
        [plain, exponent] -> {plain, String.to_integer(exponent)}
      end

    [whole | fraction] = :binary.split(mantissa, ".")
    digits = (whole <> Enum.join(fraction)) |> String.trim_trailing("0")
    decimal_position = byte_size(whole) + exponent

    {sign, digits, decimal_position}
  end

  defp layout_float({sign, digits, decimal_position})
       when decimal_position >= -5 and decimal_position <= 21 do
    sign <> decimal_layout(digits, decimal_position)
  end

  defp layout_float({sign, <<first, rest::binary>>, decimal_position}) do
    mantissa = if rest == "", do: <<first>>, else: <<first, ?., rest::binary>>
    exponent = decimal_position - 1
    exponent_sign = if exponent >= 0, do: "+", else: ""
    sign <> mantissa <> "e" <> exponent_sign <> Integer.to_string(exponent)
  end

  defp decimal_layout(digits, decimal_position) when decimal_position <= 0 do
    "0." <> String.duplicate("0", -decimal_position) <> digits
  end

  defp decimal_layout(digits, decimal_position) when decimal_position >= byte_size(digits) do
    digits <> String.duplicate("0", decimal_position - byte_size(digits))
  end

  defp decimal_layout(digits, decimal_position) do
    <<whole::binary-size(decimal_position), fraction::binary>> = digits
    whole <> "." <> fraction
  end
end
