defmodule Commonplace.ValueFixtureRouter do
  @moduledoc false

  alias Commonplace.Value

  def route_term(term, receiver, route) do
    with {:ok, value} <- Value.new(term) do
      route(value, receiver, route)
    end
  end

  def route(%Value{} = value, receiver, :local) do
    send(receiver, {:fixture_router, value})
    :ok
  end

  def route(%Value{} = value, receiver, :encoded) do
    with {:ok, decoded} <- value |> Value.encode() |> Value.from_canonical_json() do
      send(receiver, {:fixture_router, decoded})
      :ok
    end
  end

  def route(_term, _receiver, _route), do: {:error, :value_required}
end
