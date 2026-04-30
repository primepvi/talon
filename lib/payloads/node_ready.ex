defmodule Talon.Payloads.Node.Ready do
  use Talon.Schema

  defmodule App do
    use Talon.Schema

    field(:id, :string, required: true)
    field(:status, :string, required: true)

    @type t() :: %{
            id: String.t(),
            status: String.t()
          }
  end

  field(:apps, :list, of: :schema, schema: App, required: true)

  @type t() :: %{
    apps: list(App.t())
  }
end
