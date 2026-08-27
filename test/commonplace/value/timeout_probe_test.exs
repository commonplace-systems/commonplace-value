defmodule Commonplace.Value.TimeoutProbeTest do
  use ExUnit.Case, async: false

  @tag timeout: 100
  test "probe: a test that exceeds its own timeout" do
    Process.sleep(400)
    assert true
  end
end
