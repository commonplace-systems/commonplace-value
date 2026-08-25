defmodule Commonplace.Value.DomainTest do
  use ExUnit.Case, async: true

  alias Commonplace.Value.Domain
  alias Commonplace.Value.Error
  alias Commonplace.Value.Limits

  @max_safe_integer 9_007_199_254_740_991

  test "domain accepts nil and true and false" do
    assert {:ok, nil} = Domain.validate(nil)
    assert {:ok, true} = Domain.validate(true)
    assert {:ok, false} = Domain.validate(false)
  end

  test "domain accepts a UTF-8 string including astral plane characters" do
    assert {:ok, "plain 😀 text"} = Domain.validate("plain 😀 text")
  end

  test "domain accepts an empty list an empty map and an empty string key" do
    assert {:ok, []} = Domain.validate([])
    assert {:ok, %{}} = Domain.validate(%{})
    assert {:ok, %{"" => nil}} = Domain.validate(%{"" => nil})
  end

  test "domain accepts nested lists and maps recursively" do
    input = %{"a" => [1.0, %{"b" => [true, nil]}]}
    assert {:ok, %{"a" => [1, %{"b" => [true, nil]}]}} = Domain.validate(input)
  end

  test "domain rejects an atom other than nil true false with :atom_not_allowed" do
    assert_error(Domain.validate(%{"a" => [:nope]}), :atom_not_allowed, "/a/0")
  end

  test "domain rejects a tuple with :tuple_not_allowed" do
    assert_error(Domain.validate(%{"tuple" => {1, 2}}), :tuple_not_allowed, "/tuple")
  end

  test "domain rejects a struct with :struct_not_allowed" do
    assert_error(Domain.validate(%{"value" => %Limits{}}), :struct_not_allowed, "/value")
  end

  test "domain rejects a struct that derives the JSON encoder protocol" do
    struct = ~D[2026-08-25]
    assert is_binary(JSON.encode!(struct))
    assert_error(Domain.validate(%{"encoded" => struct}), :struct_not_allowed, "/encoded")
  end

  test "domain rejects a pid a reference and a port with :runtime_reference_not_allowed" do
    {:ok, port} = StringIO.open("")

    for {term, path} <- [{self(), "/0"}, {make_ref(), "/1"}, {port, "/2"}] do
      index = String.to_integer(String.trim_leading(path, "/"))

      assert_error(
        Domain.validate(List.replace_at([nil, nil, nil], index, term)),
        :runtime_reference_not_allowed,
        path
      )
    end
  end

  test "domain rejects a function with :unsupported_term" do
    assert_error(Domain.validate(%{"fn" => fn -> :ok end}), :unsupported_term, "/fn")
  end

  test "domain rejects an improper list with :improper_list" do
    assert_error(Domain.validate(%{"items" => [1 | 2]}), :improper_list, "/items/1")
  end

  test "domain rejects a map with a non-string key with :non_string_key" do
    assert_error(Domain.validate(%{"outer" => %{atom: 1}}), :non_string_key, "/outer")
  end

  test "domain rejects a non-UTF-8 binary with :invalid_utf8" do
    assert_error(Domain.validate([<<255>>]), :invalid_utf8, "/0")
  end

  test "domain rejects a non-UTF-8 object key with :invalid_utf8" do
    assert_error(Domain.validate(%{"outer" => %{<<255>> => nil}}), :invalid_utf8, "/outer")
  end

  test "domain rejects a bitstring that is not a binary" do
    assert_error(Domain.validate(%{"bits" => <<1::1>>}), :unsupported_term, "/bits")
  end

  test "domain reports the exact path of a deeply nested rejected term" do
    input = %{"a" => [%{"b/c" => [0, 1, {:rejected}]}]}
    assert_error(Domain.validate(input), :tuple_not_allowed, "/a/0/b~1c/2")
  end

  test "domain accepts the maximum safe positive and negative integers" do
    assert {:ok, @max_safe_integer} = Domain.validate(@max_safe_integer)
    assert {:ok, -@max_safe_integer} = Domain.validate(-@max_safe_integer)
  end

  test "domain rejects an integer one above the maximum safe integer with :integer_out_of_range" do
    assert_error(Domain.validate(@max_safe_integer + 1), :integer_out_of_range, "")
  end

  test "domain rejects an integer one below the minimum safe integer with :integer_out_of_range" do
    assert_error(Domain.validate(-@max_safe_integer - 1), :integer_out_of_range, "")
  end

  # ⭐ THE INSTRUMENT, NOT JUST AN ARM. Spec §5.1 requires NaN and infinities
  # rejected, and §19.2 hedges: "where the runtime can construct them". On OTP 27
  # it cannot, so `:non_finite_number` is unreachable from validate/1 and no
  # honest arm can drive it (see docs/spec-errata.md V7). What CAN be tested is
  # the premise that makes the guard unreachable -- so this arm pins the premise.
  #
  # ⛔ A test asserting only that things fail is indistinguishable from a test
  # whose channel is broken. The FINITE CONTROL is therefore first and must
  # SUCCEED through the same channels: if 1.0 also stopped arriving, this arm
  # would be measuring its own blindness rather than the runtime's refusal.
  test "OTP rejects NaN and infinities before they can become domain inputs" do
    # positive control -- every channel below must carry a finite float
    assert <<control::float-64>> = <<0x3FF0000000000000::unsigned-64>>
    assert control == 1.0
    assert :erlang.binary_to_term(<<131, 70, 63, 240, 0, 0, 0, 0, 0, 0>>) == 1.0
    assert :erlang.binary_to_float("1.0") == 1.0

    non_finite_bits = [
      {0x7FF0000000000000, "+infinity"},
      {0xFFF0000000000000, "-infinity"},
      {0x7FF8000000000001, "NaN"}
    ]

    for {bits, _label} <- non_finite_bits do
      assert_raise MatchError, fn -> <<_number::float-64>> = <<bits::unsigned-64>> end

      assert_raise ArgumentError, fn ->
        :erlang.binary_to_term(<<131, 70>> <> <<bits::unsigned-64>>)
      end
    end

    # arithmetic routes: overflow, 0/0, x/0, log(0)
    assert_raise ArithmeticError, fn -> 1.0e308 * 10 end
    assert_raise ArithmeticError, fn -> 0.0 / 0.0 end
    assert_raise ArithmeticError, fn -> 1.0 / 0.0 end
    assert_raise ArithmeticError, fn -> :math.log(0.0) end

    # textual routes
    assert_raise ArgumentError, fn -> :erlang.list_to_float(~c"inf") end
    assert_raise ArgumentError, fn -> :erlang.binary_to_float("inf") end
  end

  test "domain normalizes negative zero to positive zero" do
    assert {:ok, zero} = Domain.validate(-0.0)
    assert zero === 0
  end

  test "domain normalizes an integral float to an integer" do
    assert {:ok, number} = Domain.validate(42.0)
    assert number === 42
  end

  test "domain leaves a non integral float as a float" do
    assert {:ok, number} = Domain.validate(1.5)
    assert number === 1.5
  end

  test "domain rejects a float whose integral value is outside the safe range" do
    assert {:ok, number} = Domain.validate(1.0e20)
    assert number === 1.0e20
  end

  test "error does not reproduce the rejected value" do
    secret = "DISTINCTIVE-SECRET-VALUE-7d6f5a"
    assert {:error, %Error{} = error} = Domain.validate(%{"bad" => {:no, secret}})

    refute secret in Map.values(error)
    refute Exception.message(error) =~ secret
    refute inspect(error) =~ secret
  end

  test "invalid limits are returned as a structured construction error" do
    assert_error(
      Domain.validate(nil, limits: %Limits{max_depth: 0}),
      :invalid_limits,
      ""
    )
  end

  defp assert_error(result, reason, path) do
    assert {:error,
            %Error{
              operation: :construct,
              reason: ^reason,
              path: ^path,
              limit: nil,
              actual: nil
            }} = result
  end
end
