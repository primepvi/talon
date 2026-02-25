defmodule Talon.Payloads.App.Create do
  defstruct [:app_id, :name, :image, :strategy, :resources, env: %{}, repo: nil, branch: "main", commit: "HEAD"]

  @type strategy() :: :dockerfile | :registry
  @type t() :: %__MODULE__{
    app_id: String.t(),
    name: String.t(),
    image: String.t(),
    strategy: strategy(),
    resources: %{memory: integer(), cpu: float()},
    env: map(),
    repo: String.t(),
    branch: String.t(),
    commit: String.t(),
  }

  def from_map(map) do
    %__MODULE__{
      app_id: map["app_id"],
      name: map["name"],
      image: map["image"],
      strategy: String.to_existing_atom(map["strategy"]),
      resources: map["resources"],
      env: map["env"] || %{},
      repo: map["repo"],
      branch: map["branch"],
      commit: map["commit"]
    }
  end
end
