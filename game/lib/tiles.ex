defmodule Wordiverse.Game.Tile do
  defstruct [
    letter: nil,
    value: 1,
  ]
end

defmodule Wordiverse.Game.Tiles do
  @moduledoc """
  This is our Wordiverse Game Tiles
  The configuration of all avaialable tiles.
  """
  alias Wordiverse.Game.Tile

  @doc """
  create tiles (based on game type)

http://www.wordfeudrules.com/WordfeudRulePage.aspx
  """
  def create_list(:wordfeud) do
    list = []
    list = add(list, "a", 1, 10)
    list = add(list, "b", 4, 2)
    list = add(list, "c", 4, 2)
    list = add(list, "d", 2, 5)
    list = add(list, "e", 1, 12)
    list = add(list, "f", 4, 2)
    list = add(list, "g", 3, 3)
    list = add(list, "h", 4, 3)
    list = add(list, "i", 1, 9)
    list = add(list, "j", 10, 1)
    list = add(list, "k", 5, 1)
    list = add(list, "l", 1, 4)
    list = add(list, "m", 3, 2)
    list = add(list, "n", 1, 6)
    list = add(list, "o", 1, 7)
    list = add(list, "p", 4, 2)
    list = add(list, "q", 10, 1)
    list = add(list, "r", 1, 6)
    list = add(list, "s", 1, 5)
    list = add(list, "t", 1, 7)
    list = add(list, "u", 2, 4)
    list = add(list, "v", 4, 2)
    list = add(list, "w", 4, 2)
    list = add(list, "x", 4, 1)
    list = add(list, "y", 4, 2)
    list = add(list, "z", 10, 1)
    list = add(list, "?", 0, 2)
    Enum.reverse(list)
  end
  def create_list(:scrabble) do
    list = []
    list = add(list, "a", 1, 9)
    list = add(list, "b", 3, 2)
    list = add(list, "c", 3, 2)
    list = add(list, "d", 2, 4)
    list = add(list, "e", 1, 12)
    list = add(list, "f", 4, 2)
    list = add(list, "g", 2, 3)
    list = add(list, "h", 4, 2)
    list = add(list, "i", 1, 9)
    list = add(list, "j", 8, 1)
    list = add(list, "k", 5, 1)
    list = add(list, "l", 1, 4)
    list = add(list, "m", 3, 2)
    list = add(list, "n", 1, 6)
    list = add(list, "o", 1, 8)
    list = add(list, "p", 3, 2)
    list = add(list, "q", 10, 1)
    list = add(list, "r", 1, 6)
    list = add(list, "s", 1, 4)
    list = add(list, "t", 1, 6)
    list = add(list, "u", 1, 4)
    list = add(list, "v", 4, 2)
    list = add(list, "w", 4, 2)
    list = add(list, "x", 8, 1)
    list = add(list, "y", 4, 2)
    list = add(list, "z", 10, 1)
    list = add(list, "?", 0, 2)
    Enum.reverse(list)
  end

  def add(tiles, letter, value, _count = 0), do: tiles
  def add(tiles, letter, value, count) do
    [
      %Wordiverse.Game.Tile{letter: letter, value: value}
      |
      add(tiles, letter, value, (count - 1))
    ]
  end

  @doc """
  get random tiles until the player has 7
  """
  def get(tiles, count \\ 1) do
  end

end
