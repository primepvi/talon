defmodule Talon.Models.App do
  alias Talon.Models.App.Resources, as: AppResources
  
  use Talon.Schema
  field(:id, :string, required: true)
  field(:deploy_id, :string)
  field(:name, :string, required: true)
  field(:repo, :string, required: true)
  field(:resources, :schema, required: true, schema: AppResources)
  field(:env, :map, required: true)
  field(:status, :atom, required: true)

  @type status() :: :stopped | :starting | :running | :stopping | :error | :unknown

  @type t() :: %{
          id: String.t(),
          deploy_id: String.t() | nil,
          name: String.t(),
          repo: String.t(),
          resources: AppResources.t(),
          env: map(),
          status: status()
        }
end
