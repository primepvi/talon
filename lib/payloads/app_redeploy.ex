defmodule Talon.Payloads.App.Redeploy do
  import Talon.Payloads.Validator

  defstruct [
    :app_id,
    :deploy_id,
    :changes,
    name: nil,
    image: nil,
    strategy: nil,
    env: nil,
    repo: nil,
    branch: nil,
    commit: nil,
    resources: nil
  ]

  defp validate_raw(payload) do
    resources = payload["resources"]

    validate(payload, [
      required(payload, ["app_id", "deploy_id", "changes"]),
      validate_string(payload, "app_id"),
      validate_string(payload, "deploy_id"),
      validate_string(payload, "name"),
      validate_string(payload, "image"),
      validate_atom(payload, "strategy", [:dockerfile, :registry]),
      validate_map(payload, "resources"),
      validate_positive(resources, "cpu"),
      validate_integer(resources, "memory"),
      validate_positive(resources, "memory"),
      validate_map_of_strings(payload, "env"),
      validate_string(payload, "repo"),
      validate_string(payload, "branch"),
      validate_string(payload, "commit")
    ])
  end

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

  def from_map(map) do
    case validate_raw(map) do
      {:ok, _map} ->
        strategy = if map["strategy"], do: String.to_existing_atom(map["strategy"]), else: nil

        {:ok,
         %__MODULE__{
           app_id: map["app_id"],
           deploy_id: map["deploy_id"],
           changes: map["changes"] || [],
           name: map["name"],
           image: map["image"],
           strategy: strategy,
           resources: map["resources"],
           env: map["env"] || %{},
           repo: map["repo"],
           branch: map["branch"],
           commit: map["commit"]
         }}

      error ->
        error
    end
  end
end
