defmodule Commonplace.Value.Error do
  @moduledoc """
  A structured, value-safe failure returned by value-domain operations.
  """

  defexception operation: :construct,
               reason: :unsupported_term,
               path: "",
               limit: nil,
               actual: nil

  @type t :: %__MODULE__{
          operation: :construct | :decode,
          reason: atom(),
          path: String.t(),
          limit: integer() | nil,
          actual: integer() | nil
        }

  @impl Exception
  def message(%__MODULE__{operation: operation, reason: reason, path: path}) do
    "#{operation} failed with #{reason} at JSON Pointer #{inspect(path)}"
  end
end
