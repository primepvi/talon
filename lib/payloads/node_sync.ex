defmodule Talon.Payloads.Node.Sync do
  use Talon.Schema

  defmodule Item do
    use Talon.Schema

    field(:app, :schema, schema: Talon.Models.App, required: true)
    field(:deploy, :schema, schema: Talon.Models.Deploy)

    @type t() :: %{
            app: Talon.Models.App.t(),
            deploy: Talon.Models.Deploy.t() | nil
          }
  end

  field(:buildpacks, :list, of: :schema, schema: Talon.Models.Buildpack, required: true)
  field(:items, :list, of: :schema, schema: Item, required: true)

  @type t() :: %{
          buildpacks: list(Talon.Models.Buildpack.t()),
          items: list(Item.t())
        }
end
