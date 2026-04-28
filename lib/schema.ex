defmodule Talon.Schema do
  defmacro __using__(_opts) do
    quote do
      import Talon.Schema

      Module.register_attribute(__MODULE__, :schema_fields, accumulate: true)

      @before_compile Talon.Schema
    end
  end

  defmacro field(name, type, opts \\ []) do
    quote do
      @schema_fields {unquote(name), unquote(type), unquote(opts)}
    end
  end

  defmacro __before_compile__(env) do
    fields =
      Module.get_attribute(env.module, :schema_fields)
      |> Enum.reverse()
      |> Macro.escape()

    quote do
      def validate(data) when is_map(data) do
        Talon.Schema.run(data, unquote(fields))
      end
    end
  end

  def run(data, fields) do
    data =
      data
      |> normalize()
      |> apply_defaults(fields)

    errors =
      fields
      |> Enum.flat_map(fn {name, type, opts} ->
        validate_field(name, type, opts, data)
      end)

    case errors do
      [] -> {:ok, data}
      _ -> {:error, errors}
    end
  end

  defp normalize(data) do
    Enum.reduce(data, %{}, fn
      {k, v}, acc when is_atom(k) ->
        Map.put(acc, k, v)

      {k, v}, acc when is_binary(k) ->
        try do
          Map.put(acc, String.to_existing_atom(k), v)
        rescue
          ArgumentError ->
            acc
        end

      _, acc ->
        acc
    end)
  end

  defp apply_defaults(data, fields) do
    Enum.reduce(fields, data, fn {name, _type, opts}, acc ->
      cond do
        Map.has_key?(acc, name) ->
          acc

        Keyword.has_key?(opts, :default) ->
          Map.put(acc, name, opts[:default])

        true ->
          acc
      end
    end)
  end

  defp validate_field(name, type, opts, data) do
    value = Map.get(data, name)

    cond do
      is_nil(value) and opts[:required] ->
        [{name, "#{field_name(name)} is required"}]

      is_nil(value) ->
        []

      true ->
        validate_type(name, type, value, opts)
    end
  end

  defp validate_type(name, :string, value, _opts)
       when not is_binary(value),
       do: [{name, "#{field_name(name)} must be a string."}]

  defp validate_type(name, :integer, value, _opts)
       when not is_integer(value),
       do: [{name, "#{field_name(name)} must be an integer."}]

  defp validate_type(name, :float, value, _opts)
       when not is_float(value),
       do: [{name, "#{field_name(name)} must be a float."}]

  defp validate_type(name, :number, value, _opts)
       when not is_number(value),
       do: [{name, "#{field_name(name)} must be a number."}]

  defp validate_type(name, :boolean, value, _opts)
       when not is_boolean(value),
       do: [{name, "#{field_name(name)} must be a boolean."}]

  defp validate_type(name, :map, value, _opts)
       when not is_map(value),
       do: [{name, "#{field_name(name)} must be a map."}]

  defp validate_type(name, :list, value, opts) do
    type = opts[:of]

    cond do
      is_nil(type) ->
        [
          {name, "field #{field_name(name)} elements type 'of' was not provided"}
        ]

      not is_list(value) ->
        [{name, "#{field_name(name)} must be a list."}]

      true ->
        errors =
          value
          |> Enum.with_index()
          |> Enum.flat_map(fn {element, index} ->
            validate_type(
              "#{field_name(name)}[#{index}]",
              type,
              element,
              opts
            )
          end)

        case errors do
          [] -> []
          _ -> [{name, errors}]
        end
    end
  end

  defp validate_type(name, :schema, value, opts) do
    schema = opts[:schema]

    cond do
      is_nil(schema) ->
        [{name, "field #{field_name(name)} schema was not provided"}]

      not is_map(value) ->
        [{name, "#{field_name(name)} must be a map."}]

      true ->
        case schema.validate(value) do
          {:ok, _} ->
            []

          {:error, errors} ->
            [{name, errors}]
        end
    end
  end

  defp validate_type(_name, :any, _value, _opts),
    do: []

  defp validate_type(_name, _type, _value, _opts),
    do: []

  defp field_name(name) when is_atom(name),
    do: Atom.to_string(name)

  defp field_name(name) when is_binary(name),
    do: name
end
