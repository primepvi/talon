defmodule Talon.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Talon.App.Process.Registry},
      Talon.App.Supervisor,
      Talon.App.PortManager,
      Talon.Infra.Docker,
      Talon.Panel.Connection,
      {Task.Supervisor, name: Talon.TaskSupervisor}
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: Talon.Supervisor])
  end
end
