defmodule Commonplace.Value.Limits do
  @moduledoc """
  Resource limits applied at every trust boundary (spec §13).

  The defaults below are the specification's table, verbatim. They are a
  protocol surface: §22 lists *"changing default limits in a way that rejects
  previously valid boundary traffic"* as a **breaking change**, which is why
  they are pinned by a test rather than merely written down.

  `validate/1` checks caller-supplied limits (§13 rule 5's positive finite
  integers, rule 6's ban on `:infinity`). Covered by the arms
  `limits validation accepts the default limit set`,
  `limits validation rejects a zero or negative bound with :invalid_limits`,
  `limits validation rejects a non-integer bound with :invalid_limits` and
  `limits validation rejects :infinity for any bound with :invalid_limits`.

  ⛔ **This module does not ENFORCE any limit.** Enforcement is round P2; until
  its arms exist, nothing here may be described as implemented.
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
