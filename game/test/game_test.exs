defmodule GameTest do
  use ExUnit.Case
  doctest Wordiverse.Game

  test "greets the world" do
    assert Wordiverse.Game.hello() == :world
  end
end
