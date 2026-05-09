defmodule Talon.Infra.Docker.Dockerfile do
  alias Talon.Models.Buildpack

  @spec generate(Buildpack.t()) :: String.t()
  def generate(%{ "image" => image, "params" => params, "env" => env, "steps" => steps} = bp) do
    [
      "FROM #{image}",
      generate_args_lines(params),
      generate_envs_lines(env),
      generate_steps_lines(steps)
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end

  @spec generate_args_lines(list(Buildpack.Param.t())) :: list(String.t())
  defp generate_args_lines(params) do
    Enum.map(params, fn
      %{name: name, default: nil} -> "ARG #{name}"
      %{name: name, default: default} -> "ARG #{name}=#{default}"
    end)
  end

  @spec generate_envs_lines(list(Buildpack.Env.t())) :: list(String.t())
  defp generate_envs_lines(envs) do
    Enum.map(envs, fn
      %{name: name, value: value} when not is_nil(value) -> "ENV #{name}=#{value}"
      %{name: name, from_param: param} when not is_nil(param) -> "ENV #{name}=$#{param}"
    end)
  end

  @spec generate_steps_lines(list(Buildpack.Step.t())) :: list(String.t())
  defp generate_steps_lines(steps), do: Enum.map(steps, &generate_step_line/1)

  @spec generate_step_line(Buildpack.Step.t()) :: String.t()
  defp generate_step_line(%{"type" => "copy", "src" => src, "dest" => dest}), do: "COPY #{src} #{dest}"
  defp generate_step_line(%{"type" => "run", "command" => cmd}), do: "RUN #{inspect(cmd)}"
  defp generate_step_line(%{"type" => "cmd", "command" => cmd}), do: "CMD #{inspect(cmd)}"
  defp generate_step_line(%{"type" => "workdir", "path" => path}), do: "WORKDIR #{path}"

  defp generate_step_line(%{"type" => "entrypoint", "command" => cmd}),
    do: "ENTRYPOINT #{inspect(cmd)}"

  defp generate_step_line(%{"type" => "add", "src" => src, "dest" => dest}), do: "ADD #{src} #{dest}"
end
