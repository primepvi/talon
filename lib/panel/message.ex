defmodule Talon.Panel.Message do
  defstruct [:type, :correlation_id, :payload]

  @type t(payload) :: %__MODULE__{
    type: String.t(),
    correlation_id: String.t(),
    payload: payload,
  }
end
