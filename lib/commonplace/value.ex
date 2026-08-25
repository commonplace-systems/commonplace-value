defmodule Commonplace.Value do
  @moduledoc """
  An inert portable value identified by its RFC 8785 canonical bytes.
  """

  alias Commonplace.Value.{Domain, Encoder, Error, Limits, Metrics}

  @enforce_keys [:canonical_bytes, :normalized_term, :metrics]
  defstruct @enforce_keys

  @opaque t :: %__MODULE__{
            canonical_bytes: binary(),
            normalized_term: Domain.normalized_term(),
            metrics: Metrics.t()
          }

  @spec new(term(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new(term, opts \\ []) do
    limits = Keyword.get(opts, :limits, %Limits{})

    with {:ok, normalized, metrics} <- Domain.validate(term, opts) do
      canonical_bytes = Encoder.encode(normalized)
      encoded_byte_length = byte_size(canonical_bytes)

      if encoded_byte_length > limits.max_bytes do
        {:error,
         %Error{
           operation: :construct,
           reason: :max_bytes_exceeded,
           path: "",
           limit: limits.max_bytes,
           actual: encoded_byte_length
         }}
      else
        metrics = %{metrics | encoded_byte_length: encoded_byte_length}

        {:ok,
         %__MODULE__{
           canonical_bytes: canonical_bytes,
           normalized_term: normalized,
           metrics: metrics
         }}
      end
    end
  end

  @spec encode(t()) :: binary()
  def encode(%__MODULE__{canonical_bytes: canonical_bytes}), do: canonical_bytes

  @spec to_term(t()) :: Domain.normalized_term()
  def to_term(%__MODULE__{normalized_term: normalized_term}), do: normalized_term

  @spec equal?(t(), t()) :: boolean()
  def equal?(%__MODULE__{canonical_bytes: left}, %__MODULE__{canonical_bytes: right}) do
    left == right
  end
end

defimpl Inspect, for: Commonplace.Value do
  import Inspect.Algebra

  def inspect(value, _opts) do
    concat([
      "#Commonplace.Value<bytes: ",
      Integer.to_string(byte_size(value.canonical_bytes)),
      ">"
    ])
  end
end
