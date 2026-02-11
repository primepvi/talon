import Config

config :talon,
  docker_host: System.get_env("DOCKER_HOST", "http://localhost:2375/")
