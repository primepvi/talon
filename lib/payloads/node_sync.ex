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

  field(:items, :list, of: :schema, schema: Item, required: true)

  @type t() :: %{
          items: list(Item.t())
        }
end
