defmodule Talon.Payloads.Ack do
  use Talon.Schema

  field :error, :boolean, required: true
  field :reason, :string

  @type t() :: %{
    error: boolean(),
    reason: String.t() | nil
  }
end
