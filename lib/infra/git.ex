defmodule Talon.Infra.Git do
  @base_path Application.compile_env(:talon, :repo_directory, "./talon/")

  @spec clone(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def clone(repository, target) do
    path = @base_path <> target
    case System.cmd("git", ["clone", repository, path], stderr_to_stdout: true) do
      {_out, 0} -> {:ok, path}
      {out, _code} -> {:error, out}
    end
  end
end
