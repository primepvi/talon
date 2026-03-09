defmodule Talon.Payloads.App.Deploy do
  import Talon.Payloads.Validator

  defstruct [
    :app_id,
    :deploy_id,
    :name,
    :strategy,
    :resources,
    image: nil,
    env: %{},
    repo: nil,
    branch: "main",
    commit: "HEAD"
  ]

  defp validate_raw(payload) do
    resources = payload["resources"]

    validate(payload, [
      required(payload, ["app_id", "deploy_id", "name", "strategy", "resources"]),
      validate_string(payload, "app_id"),
      validate_string(payload, "deploy_id"),
      validate_string(payload, "name"),
      validate_string(payload, "image"),
      validate_atom(payload, "strategy", [:dockerfile, :registry]),
      validate_map(payload, "resources"),
      required(resources, ["cpu", "memory"]),
      validate_positive(resources, "cpu"),
      validate_integer(resources, "memory"),
      validate_positive(resources, "memory"),
      validate_map_of_strings(payload, "env"),
      validate_string(payload, "repo"),
      validate_string(payload, "branch"),
      validate_string(payload, "commit")
    ])
  end

  @type strategy() :: :dockerfile | :registry
  @type t() :: %__MODULE__{
          app_id: String.t(),
          deploy_id: String.t(),
          name: String.t(),
          image: String.t() | nil,
          strategy: strategy(),
          resources: %{memory: integer(), cpu: float()},
          env: map() | nil,
          repo: String.t() | nil,
          branch: String.t() | nil,
          commit: String.t() | nil
        }

  def from_map(map) do
    case validate_raw(map) do
      {:ok, _map} ->
        {:ok,
         %__MODULE__{
           app_id: map["app_id"],
           deploy_id: map["deploy_id"],
           name: map["name"],
           image: map["image"],
           strategy: String.to_existing_atom(map["strategy"]),
           resources: map["resources"],
           env: map["env"] || %{},
           repo: map["repo"],
           branch: map["branch"] || "main",
           commit: map["commit"] || "HEAD"
         }}

      error ->
        error
    end
  end
end
