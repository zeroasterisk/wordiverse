defmodule Wordiverse.GameTile do
  @moduledoc """
  A single tile, must know it's Letter and it's Value
  NOTE: a blank or joker has a letter of "?" and value of 0
  """
  defstruct [
    letter: nil,
    value: 1,
  ]
end

defmodule Wordiverse.GameTiles do
  @moduledoc """
  This is our Wordiverse GameTiles
  The configuration of all avaialable tiles.
  """

  @doc """
  create tiles (based on game type)

http://www.wordfeudrules.com/WordfeudRulePage.aspx
  """
  def create(:wordfeud) do
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
  def create(:scrabble) do
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

  def add(tiles, _letter, _value, _count = 0), do: tiles
  def add(tiles, letter, value, count) do
    [
      %Wordiverse.GameTile{letter: letter, value: value}
      |
      add(tiles, letter, value, (count - 1))
    ]
  end

  @doc """
  get random tiles until the player has 7

  ## Examples

      iex> Wordiverse.GameTiles.take_random([1, 1, 1, 1, 1, 1, 1], 2)
      {[1, 1], [1, 1, 1, 1, 1]}
  """
  def take_random(tiles, count \\ 1) when is_list(tiles) and count > 0 do
    total = Enum.count(tiles)
    [in_pile, in_hand] = tiles |> Enum.shuffle() |> Enum.chunk_every(total - count)
    {in_hand, in_pile}
  end

  @doc """
  get a set of tiles from another set, only if all are available

  ## Examples

      iex> word = ["a", "l"]
      iex> tray = ["a", "l", "b", "d", "n", "l"]
      iex> Wordiverse.GameTiles.take_from_tray(tray, word)
      {["a", "l"], ["b", "d", "n", "l"]}

      iex> word = ["a", "l", "l"]
      iex> tray = ["a", "l", "b", "d", "n", "l"]
      iex> Wordiverse.GameTiles.take_from_tray(tray, word)
      {["a", "l", "l"], ["b", "d", "n"]}

      iex> word = ["a", "l", "a", "n"]
      iex> tray = ["a", "l", "b", "d", "n", "l"]
      iex> Wordiverse.GameTiles.take_from_tray(tray, word)
      {[], ["a", "l", "b", "d", "n", "l"]}

  """
  def take_from_tray(tray, word) when is_list(tray) and is_list(word) do
    {status, word_taken, tray_left} = take_from_tray([], tray, word)
    case status do
      :ok -> {word_taken, tray_left}
      :error -> {[], tray}
    end
  end
  def take_from_tray(word_taken, tray, [] = _word_left) do
    {:ok, Enum.reverse(word_taken), tray}
  end
  def take_from_tray(word_taken, tray, [letter | word_left]) do
    case Enum.member?(tray, letter) do
      true -> take_from_tray(
        [letter | word_taken],
        List.delete(tray, letter),
        word_left
      )
      false -> {:error, [], []}
    end
  end

end
