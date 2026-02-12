import Config

config :talon,
  docker_host: System.get_env("DOCKER_HOST", "http://localhost:2375/"),
  repo_directory: System.get_env("REPO_DIRECTORY", "./talon/")
