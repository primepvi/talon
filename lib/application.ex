defmodule Talon.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Talon.Infra.Docker.Supervisor
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: Talon.Supervisor])
  end
end
