defmodule Talon.Payloads.Node.Register do
  use Talon.Schema

  field(:node_id, :string, required: true)
  field(:version, :string, required: true)

  @type t() :: %{
    node_id: String.t(),
    version: String.t()
  }
end
