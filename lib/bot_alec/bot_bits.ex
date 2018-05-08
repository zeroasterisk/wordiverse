defmodule Wordza.BotBits do
  @moduledoc """
  A set of possibly shared "bits" for all Bots...

  These are utilities for aiding in common functionalities for all/many bots.

  - start_yx_possible?
  - build_all_words_for_letters
  """
  alias Wordza.GameBoard
  alias Wordza.GameTiles
  alias Wordza.Dictionary

  @doc """
  Is the y+x a possible start on the board?
  - must be an unplayed, valid square
  - must be within 7 of a played letter
  """
  def start_yx_possible?(board, y, x, tiles_in_tray) do
    !!(
      board
      |> start_yx_playable?(y, x)
      |> start_yx_within_tile_count?(y, x, Enum.count(tiles_in_tray))
    )
  end

  @doc """
  A start must not be on an already played spot
  """
  def start_yx_playable?(board, y, x) do
    case yx_playable?(board, y, x) do
      true -> board
      _ -> false
    end
  end


  @doc """
  A start must within 7 of an already played spot
  in either x or y
  """
  def start_yx_within_tile_count?(false, _y, _x, _t), do: false
  def start_yx_within_tile_count?(_board, _y, _x, 0), do: false
  def start_yx_within_tile_count?(board, y, x, tile_count) do
    [] |> get_xy_played(board, y, x, tile_count) |> Enum.any?()
  end

  @doc """
  Get a list of "is tile played" for all placements
  down and right of a given y+x coordinate
  for the tile_count amount (usually 7)

  This is used to see if a y+x is "within reach" of a played square
  """
  def get_xy_played(acc, _board, _y, _x, 0), do: acc
  def get_xy_played(acc, board, y, x, tile_count) do
    [
      yx_played?(board, y + tile_count, x),
      yx_played?(board, y, x + tile_count)
      | acc
    ] |> get_xy_played(board, y, x, tile_count - 1)
  end

  @doc """
  On a board, is a y+x yx_playable?
  It must be a valid place, and have no letter already
  """
  def yx_playable?(board, y, x) do
    is_nil(board[y][x][:letter]) and !is_nil(board[y][x])
  end

  @doc """
  On a board, is a y+x yx_played already?
  It must be a valid place, and have a letter already
  """
  def yx_played?(board, y, x) do
    is_bitstring(board[y][x][:letter])
  end

  @doc """
  Extract all possible start yx squares from a board

  ## Examples

      iex> board = Wordza.GameBoard.create(:mock)
      iex> tiles = Wordza.GameTiles.add([], "a", 1, 7)
      iex> Wordza.BotBits.get_all_start_yx(board, tiles)
      []

      iex> letters_yx = [["A", 2, 2]]
      iex> board = Wordza.GameBoard.create(:mock) |> Wordza.GameBoard.add_letters(letters_yx)
      iex> tiles = Wordza.GameTiles.add([], "a", 1, 7)
      iex> Wordza.BotBits.get_all_start_yx(board, tiles)
      [[0, 2], [1, 2], [2, 0], [2, 1]]

      iex> letters_yx = [["A", 2, 2], ["A", 2, 3], ["A", 2, 4]]
      iex> board = Wordza.GameBoard.create(:mock) |> Wordza.GameBoard.add_letters(letters_yx)
      iex> tiles = Wordza.GameTiles.add([], "a", 1, 7)
      iex> Wordza.BotBits.get_all_start_yx(board, tiles)
      [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 0], [2, 1]]
  """
  def get_all_start_yx(board, tiles_in_tray) do
    board
    |> GameBoard.to_yx_list()
    |> Enum.filter(fn([y, x]) -> start_yx_possible?(board, y, x, tiles_in_tray) end)
  end

  @doc """
  Return all possible start yx squares for an empty board

  ## Examples

      iex> board = Wordza.GameBoard.create(:mock)
      iex> tiles = Wordza.GameTiles.add([], "a", 1, 7)
      iex> Wordza.BotBits.get_all_start_yx_first_play(board, tiles)
      [[2, 0], [2, 1], [2, 2], [0, 2], [1, 2], [2, 2]]
  """
  def get_all_start_yx_first_play(board, tiles_in_tray) do
    {_total_y, _total_x, center_y, center_x} = board |> GameBoard.measure
    x_count = min(Enum.count(tiles_in_tray), center_x)
    y_count = min(Enum.count(tiles_in_tray), center_y)
    horizontal = for x <- Range.new(x_count * -1, 0) do
      [center_y, center_x + x]
    end
    vertical = for y <- Range.new(y_count * -1, 0) do
      [center_y + y, center_x]
    end
    horizontal ++ vertical
  end

  @doc """
  Get all the possible word-starts for a set of letters

  If "?" in letters, sub with each letter of alphabet and join results

  TODO what if there are multiple "?"
       IDEA get a normal list of all words without the "?"
       and for each "?" add every possible "next" letter to every word

  ## Examples

      iex> {:ok, _pid} = Wordza.Dictionary.start_link(:mock)
      iex> letters = ["L", "B", "D", "A", "N", "L"]
      iex> Wordza.BotBits.get_all_word_starts(letters, :mock)
      [
          ["A"],
          ["A", "L"],
          ["A", "L", "L"],
      ]
  """
  def get_all_word_starts(letters, dictionary_name) when is_list(letters) and is_atom(dictionary_name) do
    letters = letters |> GameTiles.clean_letters() |> Enum.sort()
    case Enum.member?(letters, "?") do
      false ->
        dictionary_name
        |> Dictionary.get_all_word_starts(letters)
        |> Enum.sort()
        |> Enum.uniq()
      true ->
        # TODO REFACTOR optimize this guy!
        letters
        |> letter_combos()
        # If you had no blanks, the letter_sets from your tray would be 1
        # If you had 1 blank, the letter_sets from your tray would be 26
        # If you had 2 blanks, the letter_sets from your tray would be 351
        # double-blanks = DEATH!!!
        #   reducing length of letter_sets based on count
        |> get_all_word_starts_limit()
        # TODO REFACTOR - sent all letter_sets to Dictionary as 1 (big) call
        |> Enum.reduce([], fn(letter_set, words) ->
          words_this = dictionary_name |> Dictionary.get_all_word_starts(letter_set)
          words = words ++ words_this
          words
          |> Enum.sort()
          |> Enum.uniq()
        end)
    end
  end
  def get_all_word_starts(_, dictionary_name) when is_bitstring(dictionary_name) do
    raise "BotBits.get_all_word_starts must have a game.dictionary_name as an atom, not a string"
  end
  def get_all_word_starts(_, _) do
    raise "BotBits.get_all_word_starts must have a game.dictionary_name"
  end

  def get_all_word_starts_limit(letter_sets) do
    get_all_word_starts_limit(letter_sets, letter_sets |> Enum.count())
  end
  def get_all_word_starts_limit(letter_sets, c) when c < 20, do: letter_sets
  def get_all_word_starts_limit(letter_sets, c) when c < 40 do
    letter_sets
    |> Enum.map(fn(letter_set) -> letter_set |> Enum.take(6) end)
    |> Enum.sort()
    |> Enum.uniq()
  end
  def get_all_word_starts_limit(letter_sets, c) when c < 90 do
    letter_sets
    |> Enum.map(fn(letter_set) -> letter_set |> Enum.take(4) end)
    |> Enum.sort()
    |> Enum.uniq()
  end

  @doc """
  If a set of letters has a blank,
  expand the blank into every possible value
  and mix into the non-blank letters (every possible) combination
  (sorted, unique)

      Wordza.BotBits.letter_combos(["A", "C", "B", "?"])
      [["A", "A", "B", "C"], ["A", "B", "B", "C"], ...]

  ## Examples

      iex> Wordza.BotBits.letter_combos(["A", "B", "C"])
      [["A", "B", "C"]]

      iex> Wordza.BotBits.letter_combos(["A", "C", "B"])
      [["A", "B", "C"]]

      iex> Wordza.BotBits.letter_combos(["A", "C", "B", "?"]) |> Enum.count()
      26

      iex> Wordza.BotBits.letter_combos(["A", "C", "B", "?"]) |> List.first()
      ["A", "A", "B", "C"]

      iex> Wordza.BotBits.letter_combos(["A", "C", "B", "?"]) |> List.last()
      ["A", "B", "C", "Z"]

      iex> Wordza.BotBits.letter_combos(["A", "?", "B", "?"]) |> Enum.count()
      351

      iex> Wordza.BotBits.letter_combos(["A", "?", "B", "?"]) |> List.first()
      ["A", "A", "A", "B"]

      iex> Wordza.BotBits.letter_combos(["A", "?", "B", "?"]) |> List.last()
      ["A", "B", "Z", "Z"]

  """
  def letter_combos(letters) do
    blank_count = letters |> Enum.filter(fn(l) -> l == "?" end) |> Enum.count()
    letter_set = letters
                 |> Enum.filter(fn(l) -> l != "?" end)
                 |> Enum.sort()

    [letter_set] |> letter_combos(blank_count)
  end
  def letter_combos(letter_sets, 0 = _blank_count) do
    letter_sets
    |> Enum.uniq()
    |> Enum.sort()
  end
  def letter_combos(letter_sets, blank_count) when blank_count > 0 do
    letter_sets
    |> Enum.reduce([], &letter_combo/2)
    |> letter_combos(blank_count - 1)
  end

  @doc """
  Expand a single blank into a set of letters,
  making 26 new sets of letters

  ## Examples

      iex> Wordza.BotBits.letter_combo(["A", "B", "C"], []) |> List.first()
      ["A", "A", "B", "C"]

      iex> Wordza.BotBits.letter_combo(["A", "B", "C"], []) |> List.last()
      ["A", "B", "C", "Z"]

      iex> Wordza.BotBits.letter_combo(["A", "B", "C"], []) |> Enum.count()
      26

      iex> Wordza.BotBits.letter_combo(["A", "B", "C"], [["X"]]) |> Enum.count()
      27

      iex> Wordza.BotBits.letter_combo(["A", "B", "C"], [["X"]]) |> List.last()
      ["X"]

  """
  def letter_combo(letters, letter_sets) do
    expand_blank("?", [])
    |> Enum.reduce(letter_sets, fn(letter, letter_sets) ->
      letter_set = [letter | letters] |> Enum.sort()
      [letter_set | letter_sets]
    end)
  end

  @doc """
  Expand blanks, into a list of letters

  ## Examples

      iex> Wordza.BotBits.expand_blanks(["A", "B", "C"])
      ["A", "B", "C"]

      iex> Wordza.BotBits.expand_blanks(["A", "?", "C"])
      ["A", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "C"]
  """
  def expand_blanks(letters) do
    case Enum.member?(letters, "?") do
      false -> letters
      true -> letters |> Enum.reduce([], &expand_blank/2) |> Enum.reverse() |> expand_blanks()
    end
  end
  defp expand_blank("?", acc) do
    [
      "Z", "Y", "X", "W", "V", "U", "T", "S", "R", "Q", "P", "O", "N",
      "M", "L", "K", "J", "I", "H", "G", "F", "E", "D", "C", "B", "A"
      | acc
    ]
  end
  defp expand_blank(letter, acc), do: [letter | acc]


  @doc """
  Given a start_yx determine length of word_start until played tile in the "y" direction
  Then return the count of letters between, and the played square

  ## Examples

      iex> board = Wordza.GameBoard.create(:mock) |> put_in([2, 2, :letter], "A")
      iex> Wordza.BotBits.start_yx_count_y_until_played(board, 0, 2)
      2

      iex> board = Wordza.GameBoard.create(:mock) |> put_in([2, 2, :letter], "A")
      iex> Wordza.BotBits.start_yx_count_y_until_played(board, 1, 2)
      1

      iex> board = Wordza.GameBoard.create(:mock) |> put_in([2, 2, :letter], "A")
      iex> Wordza.BotBits.start_yx_count_y_until_played(board, 1, 3)
      0
  """
  def start_yx_count_y_until_played(board, y, x, plus_y \\ 1) do
    total_y = board |> Enum.count()
    case plus_y >= total_y do
      true -> 0
      false ->
        case yx_played?(board, y + plus_y, x) do
          true -> plus_y
          false -> start_yx_count_y_until_played(board, y, x, plus_y + 1)
        end
    end
  end

  @doc """
  Given a start_yx determine length of word_start until played tile in the "y" direction
  Then return the count of letters between, and the played square

  ## Examples

      iex> board = Wordza.GameBoard.create(:mock) |> put_in([2, 2, :letter], "A")
      iex> Wordza.BotBits.start_yx_count_x_until_played(board, 2, 0)
      2

      iex> board = Wordza.GameBoard.create(:mock) |> put_in([2, 2, :letter], "A")
      iex> Wordza.BotBits.start_yx_count_x_until_played(board, 2, 1)
      1

      iex> board = Wordza.GameBoard.create(:mock) |> put_in([2, 2, :letter], "A")
      iex> Wordza.BotBits.start_yx_count_x_until_played(board, 0, 1)
      0
  """
  def start_yx_count_x_until_played(board, y, x, plus_x \\ 1) do
    total_x = board[0] |> Enum.count()
    case plus_x >= total_x do
      true -> 0
      false ->
        case yx_played?(board, y, x + plus_x) do
          true -> plus_x
          false -> start_yx_count_x_until_played(board, y, x, plus_x + 1)
        end
    end
  end

end
