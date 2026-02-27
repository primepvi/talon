defmodule Talon.Payloads.App.Redeploy do
  defstruct [:app_id, :deploy_id, :changes, name: nil, image: nil, strategy: nil, env: nil, repo: nil, branch: nil, commit: nil, resources: nil]

  @type t() :: %__MODULE__{
    app_id: String.t(),
    deploy_id: String.t(),
    changes: list(String.t()),
    name: String.t() | nil,
    image: String.t() | nil,
    strategy: Talon.Payloads.App.Create.strategy() | nil,
    resources: %{memory: integer() | nil, cpu: float() | nil} | nil,
    env: map() | nil,
    repo: String.t() | nil,
    branch: String.t() | nil,
    commit: String.t() | nil
  }
end
