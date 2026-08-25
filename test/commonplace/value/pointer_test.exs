defmodule Commonplace.Value.PointerTest do
  use ExUnit.Case, async: true

  alias Commonplace.Value.Pointer

  test "pointer for the top level value is the empty string" do
    assert Pointer.render([]) == ""
  end

  test "pointer uses decimal segments for array indices" do
    assert Pointer.render([12, 0]) == "/0/12"
  end

  test "pointer escapes tilde as ~0 and slash as ~1 in object keys" do
    assert Pointer.render(["a~/b"]) == "/a~0~1b"
  end
end
