defmodule Talon.Models.Deploy do
  use Talon.Schema

  defmodule BuildpackArgument do
    use Talon.Schema

    field(:name, :string, required: true)
    field(:value, :any, required: true)

    @type t() :: %{
            name: String.t(),
            value: any()
          }
  end

  defmodule Buildpack do
    use Talon.Schema

    field(:name, :string, required: true)
    field(:arguments, :list, of: :schema, schema: BuildpackArgument, required: true)

    @type t() :: %{
            name: String.t(),
            arguments: list(BuildpackArgument.t())
          }
  end

  field(:id, :string, required: true)
  field(:app_id, :string, required: true)
  field(:buildpack, :schema, required: true, schema: Buildpack)
  field(:branch, :string, default: "main")
  field(:commit, :string, default: "HEAD")
  field(:created_at, :string, required: true)

  @type t() :: %{
          id: String.t(),
          app_id: String.t(),
          buildpack: Buildpack.t(),
          branch: String.t(),
          commit: String.t(),
          created_at: String.t()
        }
end
