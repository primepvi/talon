defmodule Talon.Models.App do
  use Talon.Schema

  defmodule Resources do
    use Talon.Schema

    field(:cpu, :float, required: true)
    field(:memory, :integer, required: true)

    @type t() :: %{
            cpu: float(),
            memory: integer()
          }
  end

  field(:id, :string, required: true)
  field(:deploy_id, :string)
  field(:name, :string, required: true)
  field(:repo, :string, required: true)
  field(:resources, :schema, required: true, schema: Resources)
  field(:env, :map, required: true)
  field(:status, :atom, required: true)

  @type status() :: :stopped | :starting | :running | :stopping | :error | :unknown

  @type t() :: %{
          id: String.t(),
          deploy_id: String.t() | nil,
          name: String.t(),
          repo: String.t(),
          resources: Resources.t(),
          env: map(),
          status: status()
        }
end
