import Config

config :talon,
  docker_host: System.get_env("DOCKER_HOST", "http://localhost:2375/"),
  repo_directory: System.get_env("REPO_DIRECTORY", "./talon/"),
  panel_url: System.get_env("PANEL_URL", "http://localhost:3030/panel/ws"),
  panel_token: System.get_env("PANEL_TOKEN", "banana"),
  node_id: System.get_env("NODE_ID", "banana")
