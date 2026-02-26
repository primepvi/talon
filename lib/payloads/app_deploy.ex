defmodule Talon.Payloads.App.Deploy do
  defstruct [:app_id, :deploy_id]

  @type t() :: %__MODULE__{
    app_id: String.t(),
    deploy_id: String.t(),
  }

  def from_map(map) do
    %__MODULE__{
      app_id: map["app_id"],
      deploy_id: map["deploy_id"]
    }
  end
end
