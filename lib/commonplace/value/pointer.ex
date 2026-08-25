defmodule Commonplace.Value.Pointer do
  @moduledoc false

  @spec render([String.t() | non_neg_integer()]) :: String.t()
  def render(reversed_path) do
    reversed_path
    |> Enum.reverse()
    |> Enum.map_join("", fn segment -> "/" <> escape(segment) end)
  end

  defp escape(index) when is_integer(index), do: Integer.to_string(index)

  defp escape(key) when is_binary(key) do
    key
    |> String.replace("~", "~0")
    |> String.replace("/", "~1")
  end
end
