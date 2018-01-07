defmodule Wordza.PlayAssembler do
  @moduledoc """
  A useful module/struct for assembling possible plays
  """
  alias Wordza.PlayAssembler
  alias Wordza.BotBits
  alias Wordza.GameTiles
  alias Wordza.GameBoard

  defstruct [
    board: nil,
    player_key: nil,
    start_yx: [],
    dir: nil, # direction :y or :x
    word_start: [], # the starting point for this assembly
    word: [], # assembled word (in progress) including played tiles
    letters_yx: [], # all tiles played from hand/tray
    letters_left: [], # letters left in tray after played
  ]

  @doc """
  Create a PlayAssembler for a given start_yx and word_start
  This gets things start, from top or left, until the first played letter
  NOTE this will often not be a complete word, look for other functions to extend/complete
  """
  def create_y(
    %{
      board: board,
      player_key: player_key,
      tiles_in_tray: tiles_in_tray,
    } = _bot,
    [y, x] = start_yx,
    word_start
  ) do
    {tiles_to_play, tiles_left} = GameTiles.take_from_tray(tiles_in_tray, word_start)
    plus_y = BotBits.start_yx_count_y_until_played(board, y, x)
    count_word_start = Enum.count(word_start)
    case plus_y == count_word_start and Enum.count(tiles_to_play) == count_word_start do
      false -> nil
      true ->
        played_letter = board |> get_in([y + plus_y, x, :letter])
        %PlayAssembler{
          board: board,
          player_key: player_key,
          start_yx: start_yx,
          dir: :y,
          word_start: word_start,
          word: word_start ++ [played_letter],
          letters_yx: play_word_start_y([], start_yx, word_start),
          letters_left: tiles_left,
        }
    end
  end

  @doc """
  Create a PlayAssembler for a given start_yx and word_start
  This gets things start, from top or left, until the first played letter
  NOTE this will often not be a complete word, look for other functions to extend/complete
  """
  def create_x(
    %{
      board: board,
      player_key: player_key,
      tiles_in_tray: tiles_in_tray,
    } = _bot,
    [y, x] = start_yx,
    word_start
  ) do
    {tiles_to_play, tiles_left} = GameTiles.take_from_tray(tiles_in_tray, word_start)
    plus_x = BotBits.start_yx_count_x_until_played(board, y, x)
    count_word_start = Enum.count(word_start)
    case plus_x == count_word_start and Enum.count(tiles_to_play) == count_word_start do
      false -> nil
      true ->
        played_letter = board |> get_in([y, x + plus_x, :letter])
        %PlayAssembler{
          board: board,
          player_key: player_key,
          start_yx: start_yx,
          dir: :x,
          word_start: word_start,
          word: word_start ++ [played_letter],
          letters_yx: play_word_start_x([], start_yx, word_start),
          letters_left: tiles_left,
        }
    end
  end

  @doc """
  Lay down tiles for a word_start

  ## Examples

      iex> Wordza.PlayAssembler.play_word_start_y([], [0, 0], ["a", "l", "l"])
      [
        ["a", 0, 0],
        ["l", 1, 0],
        ["l", 2, 0],
      ]
  """
  def play_word_start_y(letters_yx, _start_yx, [] = _word_start), do: letters_yx |> Enum.reverse()
  def play_word_start_y(letters_yx, [y, x] = _start_yx, [letter | word_start]) do
    [[letter, y, x] | letters_yx] |> play_word_start_y([y + 1, x], word_start)
  end

  @doc """
  Lay right tiles for a word_start

  ## Examples

      iex> Wordza.PlayAssembler.play_word_start_x([], [0, 0], ["a", "l", "l"])
      [
        ["a", 0, 0],
        ["l", 0, 1],
        ["l", 0, 2],
      ]

  """
  def play_word_start_x(letters_yx, _start_yx, [] = _word_start), do: letters_yx |> Enum.reverse()
  def play_word_start_x(letters_yx, [y, x] = _start_yx, [letter | word_start]) do
    [[letter, y, x] | letters_yx] |> play_word_start_x([y, x + 1], word_start)
  end

  @doc """
  Given a board, set of tile, and a single start_yx
  Then return a list of all possible plays
  """
  # def get_all_plays_for_start_yx(
  #   %BotRando{board: board, tiles_in_tray: tiles, valid_plays: valid_plays},
  #   start_yx
  # ) do
  # end
  # def get_all_plays_for_start_yx_on_y(
  #   %BotRando{
  #     board: board,
  #     tiles_in_tray: tiles,
  #     word_starts: word_starts,
  #     valid_plays: valid_plays,
  #   } = bot,
  #   [y, x] = _start_yx
  # ) do
  #   plus_y = Wordza.BotBits.start_yx_count_y_until_played(board, y, x)
  #   valid_plays = word_starts
  #   |> Enum.filter(fn(ws) -> Enum.count(ws) == (plus_y - 1) end)
  #   |> Enum.reduce(valid_plays, fn(word_start, valid_plays) ->
  #     {word_start, tiles_left} = GameTiles.take_from_tray(tiles, word_start)
  #     played_letter = board |> get_in([y + plus_y, x, :letter])
  #     word = word_start ++ [played_letter]
  #     get_all_plays_for_start_yx_on_y_for_word_start(bot, valid_plays, word, tiles_left, y, x, plus_y)
  #   end)
  # end
  # def get_all_plays_for_start_yx_on_y_for_word_start(
  #   _bot,
  #   valid_plays,
  #   _word,
  #   [] = _tiles,
  #   _y,
  #   _x,
  #   _plus_y
  # ), do: valid_plays
  # def get_all_plays_for_start_yx_on_y_for_word_start(
  #   %BotRando{
  #     board: board,
  #     player_key: player_key,
  #   } = bot,
  #   valid_plays,
  #   word,
  #   player_key,
  #   tiles,
  #   board,
  #   y,
  #   x,
  #   plus_y
  # ) do
  #   # GamePlay.create(player_key, letters_yx)
  #   word # TODO <-- make this
  # end


end

