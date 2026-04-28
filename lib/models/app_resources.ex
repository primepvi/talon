defmodule Talon.Models.App.Resources do
  use Talon.Schema

  field(:cpu, :float, required: true)
  field(:memory, :integer, required: true)

  @type t() :: %{
          cpu: float(),
          memory: integer()
        }
end
