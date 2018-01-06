defmodule Wordza.BotBits do
  @moduledoc """
  A set of shared "bits" for all Bots...

  These are utilities for aiding in common functionalities for all/many bots.

  - start_yx_possible?
  - build_all_words_for_letters
  """
  alias Wordza.GameBoard

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
      iex> board = Wordza.GameBoard.create(:mock) |> Wordza.GameBoard.add_letters_xy(letters_yx)
      iex> tiles = Wordza.GameTiles.add([], "a", 1, 7)
      iex> Wordza.BotBits.get_all_start_yx(board, tiles)
      [[0, 2], [1, 2], [2, 0], [2, 1]]

      iex> letters_yx = [["A", 2, 2], ["A", 2, 3], ["A", 2, 4]]
      iex> board = Wordza.GameBoard.create(:mock) |> Wordza.GameBoard.add_letters_xy(letters_yx)
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
  Get all the possible word-starts for a set of letters

  letters = ["L", "B", "D", "A", "N", "A", "L"]
  Wordza.BotBits.get_all_word_starts(letters, type)
  """
  def get_all_word_starts(letters, type) do
    # get Dictionary of type
    # get_all_word_starts for that type
    # if "?" in letters, sub with each letter of alphabet and join results
    case Enum.member?(letters, "?") do
      false -> Wordza.Dictionary.get_all_word_starts(type, letters)
      true ->
        words = Wordza.Dictionary.get_all_word_starts(type, letters)
        Enum.reduce(expand_blank("?", []), words, fn(letter, words) ->
          [
            Wordza.Dictionary.get_all_word_starts(type, [letter | letters])
            | words
          ]
        end)
    end
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
      true -> Enum.reduce(letters, [], &expand_blank/2) |> Enum.reverse()
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

end
