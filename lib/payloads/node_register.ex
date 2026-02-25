defmodule Talon.Payloads.Node.Register do
  defstruct [:node_id, :version]

  @type t() :: %__MODULE__{
    node_id: String.t(),
    version: String.t()
  }
end
