defmodule Talon.Models.App.State do
  alias Talon.Models.App
  use Talon.Schema

  field(:id, :string, required: true)
  field(:deploy_id, :string, required: true)
  field(:status, :atom, required: true)
  field(:reason, :string)

  @type t() :: %{
          id: String.t(),
          deploy_id: String.t(),
          status: App.status(),
          reason: String.t() | nil
        }
end
