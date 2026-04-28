defmodule Talon.Models.Deploy do
  alias Talon.Models.Deploy.Buildpack, as: DeployBuildpack
  use Talon.Schema
  
  field(:id, :string, required: true)
  field(:app_id, :string, required: true)
  field(:buildpack, :schema, required: true, schema: DeployBuildpack)
  field(:branch, :string, default: "main")
  field(:commit, :string, default: "HEAD")
  field(:created_at, :string, required: true)

  @type t() :: %{
          id: String.t(),
          app_id: String.t(),
          buildpack: String.t(),
          branch: String.t(),
          commit: String.t(),
          created_at: String.t()
        }
end
