defmodule Wordza.GameTile do
  @moduledoc """
  A single tile, must know it's Letter and it's Value
  NOTE: a blank or joker has a letter of "?" and value of 0
  """
  defstruct [
    letter: nil,
    value: 1,
    x: nil,
    y: nil,
  ]
end

defmodule Wordza.GameTiles do
  @moduledoc """
  This is our Wordza GameTiles
  The configuration of all avaialable tiles.
  """
  require Logger
  alias Wordza.GameTiles

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
    [%Wordza.GameTile{letter: clean_letter(letter), value: value} | add(tiles, letter, value, (count - 1))]
  end
  # clean a letter or a Tile, get an upper case single letter out
  defp clean_letter(%Wordza.GameTile{letter: letter}), do: clean_letter(letter)
  defp clean_letter([letter, y, x]) when is_bitstring(letter) and is_integer(y) and is_integer(x), do: clean_letter(letter)
  defp clean_letter(letter) when is_bitstring(letter) do
    letter |> String.upcase()
  end
  defp clean_letter(letter) do
    Logger.error fn() -> "GameTiles.clean_letter invalid input #{inspect(letter)}" end
    ""
  end

  @doc """
  Add a list of tuples for letters

  ### Examples

      iex> Wordza.GameTiles.add_tuples([], [{"A", 1}, {"L", 1, 2}, {"D", 2}])
      [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "D", value: 2},
      ]

  """
  def add_tuples(tiles, []), do: tiles |> Enum.reverse()
  def add_tuples(tiles, [{letter, value, count} | tuples]), do: tiles |> add(letter, value, count) |> add_tuples(tuples)
  def add_tuples(tiles, [{letter, value} | tuples]), do: tiles |> add(letter, value, 1) |> add_tuples(tuples)

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

      iex> letters_yx = [["A", 0, 0], ["L", 0, 1], ["L", 0, 2]]
      iex> tray = [] |> Wordza.GameTiles.add_tuples([{"A", 1}, {"L", 1, 2}, {"B", 2}, {"D", 2}, {"N", 2}])
      iex> Wordza.GameTiles.take_from_tray(tray, letters_yx)
      {
        [
          %Wordza.GameTile{letter: "A", value: 1, y: 0, x: 0},
          %Wordza.GameTile{letter: "L", value: 1, y: 0, x: 1},
          %Wordza.GameTile{letter: "L", value: 1, y: 0, x: 2},
        ],
        [
          %Wordza.GameTile{letter: "B", value: 2},
          %Wordza.GameTile{letter: "D", value: 2},
          %Wordza.GameTile{letter: "N", value: 2},
        ]
      }

      iex> letters = ["A", "L"]
      iex> tray = [] |> Wordza.GameTiles.add_tuples([{"A", 1}, {"L", 1, 2}, {"B", 2}, {"D", 2}, {"N", 2}])
      iex> Wordza.GameTiles.take_from_tray(tray, letters)
      {
        [
          %Wordza.GameTile{letter: "A", value: 1},
          %Wordza.GameTile{letter: "L", value: 1},
        ],
        [
          %Wordza.GameTile{letter: "L", value: 1},
          %Wordza.GameTile{letter: "B", value: 2},
          %Wordza.GameTile{letter: "D", value: 2},
          %Wordza.GameTile{letter: "N", value: 2},
        ]
      }

      iex> letters = ["A", "L", "L"]
      iex> tray = [] |> Wordza.GameTiles.add_tuples([{"A", 1}, {"L", 1, 2}, {"B", 2}, {"D", 2}, {"N", 2}])
      iex> Wordza.GameTiles.take_from_tray(tray, letters)
      {
        [
          %Wordza.GameTile{letter: "A", value: 1},
          %Wordza.GameTile{letter: "L", value: 1},
          %Wordza.GameTile{letter: "L", value: 1},
        ],
        [
          %Wordza.GameTile{letter: "B", value: 2},
          %Wordza.GameTile{letter: "D", value: 2},
          %Wordza.GameTile{letter: "N", value: 2},
        ]
      }

      iex> letters = ["A", "L", "J"]
      iex> tray = [] |> Wordza.GameTiles.add_tuples([{"A", 1}, {"L", 1, 2}, {"B", 2}, {"D", 2}, {"N", 2}])
      iex> Wordza.GameTiles.take_from_tray(tray, letters)
      {
        [],
        [
          %Wordza.GameTile{letter: "A", value: 1},
          %Wordza.GameTile{letter: "L", value: 1},
          %Wordza.GameTile{letter: "L", value: 1},
          %Wordza.GameTile{letter: "B", value: 2},
          %Wordza.GameTile{letter: "D", value: 2},
          %Wordza.GameTile{letter: "N", value: 2},
        ]
      }
  """
  def take_from_tray(tray, letters) when is_list(tray) and is_list(letters) do
    {status, letters_taken, tray_left} = take_from_tray([], tray, letters)
    case status do
      :ok -> {letters_taken, tray_left}
      :error -> {[], tray}
    end
  end
  def take_from_tray(letters_taken, tray, [] = _letters_left) do
    {:ok, Enum.reverse(letters_taken), tray}
  end
  def take_from_tray(letters_taken, tray, [letter_input | letters_left]) do
    {letter, tray} = pop_letter(tray, clean_letter(letter_input))
    case letter do
      nil -> {:error, [], []}
      _ -> take_from_tray(
        [
          combine_letter_input(letter, letter_input) | letters_taken
        ],
        tray,
        letters_left
      )
    end
  end

  @doc """
  As we "take" a tile from a tray, we may have extra information to merge into it

  ## Examples

      iex> Wordza.GameTiles.combine_letter_input(%Wordza.GameTile{letter: "A", value: 1}, "A")
      %Wordza.GameTile{letter: "A", value: 1}

      iex> Wordza.GameTiles.combine_letter_input(%Wordza.GameTile{letter: "A", value: 1}, ["A", 0, 0])
      %Wordza.GameTile{letter: "A", value: 1, y: 0, x: 0}

      iex> Wordza.GameTiles.combine_letter_input(%Wordza.GameTile{letter: "A", value: 1}, %{letter: "A", y: 0, x: 0})
      %Wordza.GameTile{letter: "A", value: 1, y: 0, x: 0}
  """
  def combine_letter_input(letter, %{x: x, y: y} = _letter_input), do: letter |> Map.merge(%{x: x, y: y})
  def combine_letter_input(letter, [_l, y, x] = _letter_input), do: letter |> Map.merge(%{x: x, y: y})
  def combine_letter_input(letter, _letter_input), do: letter

  # def member?(tray, letter) when is_bitstring(letter) do
  #   tray |> Enum.any?(fn(tray_letter) -> clean_letter(tray_letter.letter) == clean_letter(letter) end)
  # end

  @doc """
  Pop a single letter from a Tray of tiles, like List.pop_at()

  ## Examples

      iex> tray = [] |> Wordza.GameTiles.add_tuples([{"A", 1}, {"L", 1, 2}])
      iex> Wordza.GameTiles.pop_letter(tray, "L")
      {
        %Wordza.GameTile{letter: "L", value: 1},
        [
          %Wordza.GameTile{letter: "A", value: 1},
          %Wordza.GameTile{letter: "L", value: 1},
        ]
      }

      iex> tray = [] |> Wordza.GameTiles.add_tuples([{"A", 1}, {"L", 1, 2}])
      iex> Wordza.GameTiles.pop_letter(tray, %Wordza.GameTile{letter: "L", value: 1})
      {
        %Wordza.GameTile{letter: "L", value: 1},
        [
          %Wordza.GameTile{letter: "A", value: 1},
          %Wordza.GameTile{letter: "L", value: 1},
        ]
      }
  """
  def pop_letter(tray, %Wordza.GameTile{letter: letter}), do: pop_letter(tray, letter)
  def pop_letter(tray, letter) when is_bitstring(letter) and is_list(tray) do
    index = tray |> Enum.find_index(fn(tray_letter) -> match_letter?(tray_letter, letter) end)
    case index do
      nil -> {nil, tray}
      _ -> List.pop_at(tray, index)
    end
  end
  def pop_letter(tray, letter) do
    Logger.error fn() -> "GameTiles.pop_letter invalid input #{inspect(letter)}" end
    {nil, tray}
  end

  @doc """
  Safely compare 2 letters or tiles (or a mis-matched type) via clean_letter()

  ## Examples

      iex> Wordza.GameTiles.match_letter?("a", "A")
      true

  """
  def match_letter?(letter_1, letter_2) do
    clean_letter(letter_1) == clean_letter(letter_2)
  end

end
