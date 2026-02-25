defmodule Talon.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Talon.App.ProcessRegistry},
      Talon.App.Supervisor,
      Talon.Infra.Docker,
      Talon.Panel.Connection
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: Talon.Supervisor])
  end
end
