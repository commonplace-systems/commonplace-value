defmodule Commonplace.Value.Metrics do
  @moduledoc false

  @enforce_keys [
    :encoded_byte_length,
    :node_count,
    :maximum_internal_depth,
    :maximum_string_byte_length,
    :maximum_object_member_count,
    :maximum_array_element_count,
    :representation_version
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          encoded_byte_length: non_neg_integer(),
          node_count: pos_integer(),
          maximum_internal_depth: non_neg_integer(),
          maximum_string_byte_length: non_neg_integer(),
          maximum_object_member_count: non_neg_integer(),
          maximum_array_element_count: non_neg_integer(),
          representation_version: pos_integer()
        }

  @spec empty() :: t()
  def empty do
    %__MODULE__{
      encoded_byte_length: 0,
      node_count: 0,
      maximum_internal_depth: 0,
      maximum_string_byte_length: 0,
      maximum_object_member_count: 0,
      maximum_array_element_count: 0,
      representation_version: 1
    }
  end
end
