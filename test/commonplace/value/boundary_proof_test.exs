defmodule Commonplace.Value.BoundaryProofTest do
  @moduledoc """
  This proves what can cross through the cooperative Value API and fixture router. It does not
  claim that arbitrary code sharing a BEAM VM cannot bypass the router with `send/2`. Value opacity
  is an API and cooperative-runtime property, not a cryptographic seal or hostile-code boundary.
  """

  use ExUnit.Case, async: true

  alias Commonplace.Value
  alias Commonplace.ValueFixtureRouter, as: Router

  test "a router accepting only constructed values refuses an ordinary term" do
    assert Router.route(%{"not" => "a value"}, self(), :local) == {:error, :value_required}
    refute_receive {:fixture_router, _}
  end

  test "local pass through and encoded round trip deliver equal values" do
    assert {:ok, value} = Value.new(%{"b" => [2, 1.0], "a" => "payload"})

    assert :ok = Router.route(value, self(), :local)
    assert_receive {:fixture_router, local}

    assert :ok = Router.route(value, self(), :encoded)
    assert_receive {:fixture_router, round_tripped}

    assert Value.equal?(value, local)
    assert Value.equal?(local, round_tripped)
  end

  test "a pid cannot reach the receiver through the value API" do
    assert {:error, _error} = Router.route_term(%{"nested" => [self()]}, self(), :local)
    refute_receive {:fixture_router, _}
  end

  test "a function or reference cannot reach the receiver through the value API" do
    for rejected <- [fn -> :not_data end, make_ref()] do
      assert {:error, _error} = Router.route_term(%{"nested" => [rejected]}, self(), :local)
      refute_receive {:fixture_router, _}
    end
  end
end
