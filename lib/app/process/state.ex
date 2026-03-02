defmodule Talon.App.Process.State do
  defstruct [:app, status: :empty, container_id: nil, container_port: nil, deploy_id: nil]

  @type status() :: :empty | :idle | :deploying | :redeploying | :running  | :failed | :crashed | :destroyed

  @type t() :: %__MODULE__{
    app: Talon.Payloads.App.Create.t(),
    status: status(),
    container_id: String.t() | nil,
    container_port: integer() | nil,
    deploy_id: String.t() | nil
  }
end
