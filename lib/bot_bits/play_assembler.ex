defmodule Wordza.PlayAssembler do
  @moduledoc """
  A useful module/struct for assembling possible plays
  """
  alias Wordza.GamePlay
  alias Wordza.GameInstance
  alias Wordza.GameBoard
  alias Wordza.GameTiles

  @doc """
  Create a GamePlay for a given start_yx and word_start
  This gets things started, from top or left, until the first played letter
  then it will be appendable to the next letter from the tray (repeat)
  - all fully valid words can be stored
  - all start words can be appended
  - all not valid words can be filtered out
  """
  def create_all_plays(
    %GameInstance{} = game,
    %{
      player_key: player_key,
      start_yxs: start_yxs,
      word_starts: word_starts,
    }
  ) do
    # 1. create every combo of start_yxs & word_starts (which fit?)
    plays_y = for start_yx <- start_yxs, word_start <- word_starts do
      create(game, %{direction: :y, player_key: player_key, start_yx: start_yx, word_start: word_start})
    end
    plays_x = for start_yx <- start_yxs, word_start <- word_starts do
      create(game, %{direction: :x, player_key: player_key, start_yx: start_yx, word_start: word_start})
    end
    plays = plays_y ++ plays_x |> Enum.filter(fn(%{valid: v}) -> v == true end)
    # extend via reducer
    plays = plays |> Enum.reduce(plays, fn(play, acc) -> append_remaining(game, play, acc) end)
    # (probably in a parent function)
    # TODO are these complete words?
    # TODO if blank space, append with each letter from the tray
    # TODO if played, skip to next blank space, append with each letter from the tray
    # TODO filter by played
    plays
  end


  @doc """
  Create a GamePlay for a given start_yx and word_start
  This gets things started, from top or left, until the first played letter
  then it will be appendable to the next letter from the tray (repeat)
  - all fully valid words can be stored
  - all start words can be appended
  - all not valid words can be filtered out
  """
  def create(
    %GameInstance{} = game,
    %{
      direction: :y,
      player_key: player_key,
      start_yx: start_yx,
      word_start: word_start,
    }
  ) do
    letters_yx = play_word_start_y([], start_yx, word_start)
    player_key |> GamePlay.create(letters_yx) |> GamePlay.verify_start(game)
  end
  def create(
    %GameInstance{} = game,
    %{
      direction: :x,
      player_key: player_key,
      start_yx: start_yx,
      word_start: word_start,
    }
  ) do
    letters_yx = play_word_start_x([], start_yx, word_start)
    player_key |> GamePlay.create(letters_yx) |> GamePlay.verify_start(game)
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
  Appended more plays, using every possible combination of the player's remaining tiles_in_tray
  """
  def append_remaining(%GameInstance{} = game, %GamePlay{valid: false} = _play_start, plays), do: plays
  def append_remaining(%GameInstance{} = game, %GamePlay{tiles_in_tray: []} = play_start, plays), do: [play_start | plays]
  def append_remaining(%GameInstance{} = game, %GamePlay{tiles_in_tray: tiles_in_tray} = play_start, plays) do
    next_plays = tiles_in_tray
                 |> Enum.map(fn(tile) -> append_tile(game, play_start, tile) end)
    next_plays = next_plays
                 |> Enum.filter(fn(%{valid: v}) -> v == true end)
                 |> Enum.reduce([], fn(play, acc) -> append_remaining(game, play, acc) end)
    plays ++ next_plays
  end

  @doc """
  Append a single tile to a GamePlay (following in the same direction)
  NOTE assumes the tiles_in_tray has already been removed
  """
  def append_tile(
    %GameInstance{} = game,
    %GamePlay{
      direction: direction,
      board_next: board_next,
      tiles_in_tray: tiles_in_tray,
      tiles_in_play: tiles_in_play,
      words: words,
      player_key: player_key,
      letters_yx: letters_yx,
    } = play,
    %{letter: _letter} = tile
  ) do
    [y, x] = next_yx(play)
    {tiles_from_tray, tiles_in_tray} = GameTiles.take_from_tray(tiles_in_tray, [tile])
    tile_to_play = tiles_from_tray |> List.first() |> Map.merge(%{y: y, x: x})
    play |> Map.merge(%{
      board_next: board_next |> GameBoard.add_letters([tile_to_play]),
      tiles_in_tray: tiles_in_tray,
      tiles_in_play: tiles_in_play ++ [tile_to_play],
    })
    |> GamePlay.assign_words(game)
    |> GamePlay.verify_words_are_at_least_partial(game)
    |> GamePlay.verify_no_errors()
    |> GamePlay.assign_score(game)
    # CREATE does not work... it doesn't know how to jump over the "next" tile
    # create(game, %{
    #   direction: direction,
    #   player_key: player_key,
    #   start_yx: start_yx,
    #   word_start: word_start ++ [letter]
    # })
  end

  @doc """
  Find the next playable y+x in a direction (skipping over already played)
  """
  def next_yx(%GamePlay{board_next: board, tiles_in_play: tiles_in_play, direction: :y}) do
    {total_y, _total_x, _center_y, _center_x} = GameBoard.measure(board)
    last_tile = tiles_in_play
                |> Enum.sort(fn(%{y: y1}, %{y: y2}) -> y1 < y2 end)
                |> List.last()
    y = Range.new(last_tile.y, total_y)
        |> Enum.filter(fn(y) -> y <= total_y and y > last_tile.y end)
        |> Enum.filter(fn(y) -> !GameBoard.played?(board, y, last_tile.x) end)
        |> List.first()
    [y, last_tile.x]
  end

end

