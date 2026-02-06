defmodule TalonTest do
  use ExUnit.Case
  doctest Talon

  test "greets the world" do
    assert Talon.hello() == :world
  end
end
