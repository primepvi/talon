defmodule Talon.Payloads.Node.Sync do
  alias Talon.Payloads.App

  defstruct [:apps]

  @type t() :: %__MODULE__{
          apps: list(App.Create.t())
        }

  def from_map(map) do
    apps = Enum.map(map["apps"], &App.Create.from_map/1)

    with true <-
           Enum.all?(apps, fn app ->
             {status, _value} = app
             status == :ok
           end),
         apps <-
           Enum.map(apps, fn app ->
             {_, value} = app
             value
           end) do
      {:ok,
       %__MODULE__{
         apps: apps
       }}
    else
      _ -> {:error, "Invalid node.sync payload has provided."}
    end
  end
end
