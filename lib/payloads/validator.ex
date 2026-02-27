defmodule Talon.Payloads.Validator do
  @spec validate(map(), list()) :: {:ok, map()} | {:error, list(String.t())}
  def validate(payload, rules) do
    errors =
      rules
      |> List.flatten()
      |> Enum.reject(&is_nil/1)

    case errors do
      [] -> {:ok, payload}
      _ -> {:error, errors}
    end
  end

  def required(payload, fields) do
    Enum.map(fields, fn field ->
      if Map.get(payload, field) in [nil, ""],
        do: "#{field} is required"
    end)
  end

  def validate_string(payload, field) do
    value = Map.get(payload, field)

    if not is_nil(value) and not is_binary(value),
      do: "#{field} must be a string"
  end

  def validate_atom(payload, field, allowed) do
    case Map.get(payload, field) do
      nil ->
        nil

      value when is_binary(value) ->
        case Enum.find(allowed, &(Atom.to_string(&1) == value)) do
          nil -> "#{field} must be one of: #{Enum.join(allowed, ", ")}"
          _atom -> nil
        end

      value when is_atom(value) ->
        if value not in allowed,
          do: "#{field} must be one of: #{Enum.join(allowed, ", ")}"

      _ ->
        "#{field} must be a string or atom"
    end
  end

  def validate_integer(payload, field) do
    value = Map.get(payload, field)

    if not is_nil(value) and not is_integer(value),
      do: "#{field} must be an integer"
  end

  def validate_float(payload, field) do
    value = Map.get(payload, field)

    if not is_nil(value) and not is_float(value),
      do: "#{field} must be a float"
  end

  def validate_enum(payload, field, allowed) do
    value = Map.get(payload, field)

    if not is_nil(value) and value not in allowed,
      do: "#{field} must be one of: #{Enum.join(allowed, ", ")}"
  end

  def validate_map(payload, field) do
    value = Map.get(payload, field)

    if not is_nil(value) and not is_map(value),
      do: "#{field} must be a map"
  end

  def validate_map_of_strings(payload, field) do
    value = Map.get(payload, field)

    if is_map(value) do
      invalid = Enum.reject(value, fn {k, v} -> is_binary(k) and is_binary(v) end)

      if not Enum.empty?(invalid),
        do: "#{field} must be a map of string keys and string values"
    end
  end

  def validate_positive(payload, field) do
    value = Map.get(payload, field)

    if not is_nil(value) and is_number(value) and value <= 0,
      do: "#{field} must be greater than 0"
  end
end
