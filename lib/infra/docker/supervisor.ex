defmodule Talon.Infra.Docker.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Finch,
       name: Talon.Infra.Docker.Finch,
       pools: %{:default => [size: 10, count: 2]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
