defmodule Wordza.GameTile do
  @moduledoc """
  A single tile, must know it's Letter and it's Value
  NOTE: a blank or joker has a letter of "?" and value of 0
  """
  defstruct [
    letter: nil,
    value: 1,
  ]
end

defmodule Wordza.GameTiles do
  @moduledoc """
  This is our Wordza GameTiles
  The configuration of all avaialable tiles.
  """

  @doc """
  Create a standard set of tiles (based on game type)

  http://www.wordfeudrules.com/WordfeudRulePage.aspx

  ## Examples

      iex> Wordza.GameTiles.create(:mock)
      [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
        %Wordza.GameTile{letter: "N", value: 1}
      ]
  """
  def create(:wordfeud) do
    []
    |> add("A", 1, 10)
    |> add("B", 4, 2)
    |> add("C", 4, 2)
    |> add("D", 2, 5)
    |> add("E", 1, 12)
    |> add("F", 4, 2)
    |> add("G", 3, 3)
    |> add("H", 4, 3)
    |> add("I", 1, 9)
    |> add("J", 10, 1)
    |> add("K", 5, 1)
    |> add("L", 1, 4)
    |> add("M", 3, 2)
    |> add("N", 1, 6)
    |> add("O", 1, 7)
    |> add("P", 4, 2)
    |> add("Q", 10, 1)
    |> add("R", 1, 6)
    |> add("S", 1, 5)
    |> add("T", 1, 7)
    |> add("U", 2, 4)
    |> add("V", 4, 2)
    |> add("W", 4, 2)
    |> add("X", 4, 1)
    |> add("Y", 4, 2)
    |> add("Z", 10, 1)
    |> add("?", 0, 2)
    |> Enum.reverse()
  end
  def create(:scrabble) do
    []
    |> add("A", 1, 9)
    |> add("B", 3, 2)
    |> add("C", 3, 2)
    |> add("D", 2, 4)
    |> add("E", 1, 12)
    |> add("F", 4, 2)
    |> add("G", 2, 3)
    |> add("H", 4, 2)
    |> add("I", 1, 9)
    |> add("J", 8, 1)
    |> add("K", 5, 1)
    |> add("L", 1, 4)
    |> add("M", 3, 2)
    |> add("N", 1, 6)
    |> add("O", 1, 8)
    |> add("P", 3, 2)
    |> add("Q", 10, 1)
    |> add("R", 1, 6)
    |> add("S", 1, 4)
    |> add("T", 1, 6)
    |> add("U", 1, 4)
    |> add("V", 4, 2)
    |> add("W", 4, 2)
    |> add("X", 8, 1)
    |> add("Y", 4, 2)
    |> add("Z", 10, 1)
    |> add("?", 0, 2)
    |> Enum.reverse()
  end
  def create(:mock) do
    []
    |> add("A", 1, 3)
    |> add("L", 1, 3)
    |> add("N", 1, 3)
    |> Enum.reverse()
  end
  def create(:mock_tray) do
    []
    |> add("A", 1, 2)
    |> add("L", 1, 2)
    |> add("N", 1, 1)
    |> Enum.reverse()
  end

  @doc """
  Add a count of tiles to a list of tiles

  ## Examples

      iex> Wordza.GameTiles.add([], "A", 3, 1)
      [%Wordza.GameTile{letter: "A", value: 3}]

      iex> Wordza.GameTiles.add([], "A", 3, 3)
      [
        %Wordza.GameTile{letter: "A", value: 3},
        %Wordza.GameTile{letter: "A", value: 3},
        %Wordza.GameTile{letter: "A", value: 3},
      ]
  """
  def add(tiles, _letter, _value, 0 = _count), do: tiles
  def add(tiles, letter, value, count) do
    [%Wordza.GameTile{letter: letter, value: value} | add(tiles, letter, value, (count - 1))]
  end

  @doc """
  Get random tiles until the player has 7

  ## Examples

      iex> Wordza.GameTiles.take_random([1, 1, 1, 1, 1, 1, 1], 2)
      {[1, 1], [1, 1, 1, 1, 1]}

      iex> Wordza.GameTiles.take_random([1, 1, 1, 1, 1, 1, 1], 5)
      {[1, 1, 1, 1, 1], [1, 1]}

      iex> Wordza.GameTiles.take_random([1, 1, 1, 1, 1, 1, 1], 7)
      {[1, 1, 1, 1, 1, 1, 1], []}

      iex> Wordza.GameTiles.take_random([1, 1], 99)
      {[1, 1], []}
  """
  def take_random(tiles, _count = 0) when is_list(tiles), do: {[], tiles}
  def take_random(tiles, count) when is_list(tiles) and count > 0 do
    total = Enum.count(tiles)
    tiles = tiles |> Enum.shuffle()
    in_hand = tiles |> Enum.slice(0, count)
    in_pile = tiles |> Enum.slice(count, total)
    {in_hand, in_pile}
  end

  @doc """
  Get a set of tiles from another set, only if all are available

  This allows us to remove tiles for a play, and gives us the remaining tiles

  If the player does not have the correct tiles, no changes are made

  ## Examples

      iex> word = ["A", "L"]
      iex> tray = ["A", "L", "B", "D", "N", "L"]
      iex> Wordza.GameTiles.take_from_tray(tray, word)
      {["A", "L"], ["B", "D", "N", "L"]}

      iex> word = ["A", "L", "L"]
      iex> tray = ["A", "L", "B", "D", "N", "L"]
      iex> Wordza.GameTiles.take_from_tray(tray, word)
      {["A", "L", "L"], ["B", "D", "N"]}

      iex> word = ["A", "L", "A", "N"]
      iex> tray = ["A", "L", "B", "D", "N", "L"]
      iex> Wordza.GameTiles.take_from_tray(tray, word)
      {[], ["A", "L", "B", "D", "N", "L"]}
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
