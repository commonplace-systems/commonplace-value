defmodule Commonplace.Value.Limits do
  @moduledoc """
  Resource limits applied at every trust boundary (spec §13).

  The defaults below are the specification's table, verbatim. They are a
  protocol surface: §22 lists *"changing default limits in a way that rejects
  previously valid boundary traffic"* as a **breaking change**, which is why
  they are pinned by a test rather than merely written down.

  Validation of caller-supplied limits (`:invalid_limits`, the ban on
  `:infinity` in §13 rule 6) lands in round P1 — see
  `docs/IMPLEMENTATION-PLAN-P1.md`.
  """

  defstruct max_bytes: 1_048_576,
            max_depth: 64,
            max_nodes: 100_000,
            max_string_bytes: 1_048_576,
            max_object_members: 100_000,
            max_array_elements: 100_000

  @type t :: %__MODULE__{
          max_bytes: pos_integer(),
          max_depth: pos_integer(),
          max_nodes: pos_integer(),
          max_string_bytes: pos_integer(),
          max_object_members: pos_integer(),
          max_array_elements: pos_integer()
        }

  @spec validate(t()) :: :ok | {:error, :invalid_limits}
  def validate(%__MODULE__{} = limits) do
    limits
    |> Map.from_struct()
    |> Map.values()
    |> Enum.all?(&(is_integer(&1) and &1 > 0))
    |> case do
      true -> :ok
      false -> {:error, :invalid_limits}
    end
  end

  def validate(_limits), do: {:error, :invalid_limits}
end
