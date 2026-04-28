defmodule Talon.Models.Message do
  use Talon.Schema

  field(:type, :string, required: true)
  field(:correlation_id, :string, required: true)
  field(:payload, :map, required: true)

  @type t(payload) :: %{
          type: String.t(),
          correlation_id: String.t(),
          payload: payload
        }
end
