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

  TODO bug: it will return multiple copies of the play, it should only be 1 copy
  TODO investigate: will it work if you have "?" as a tile?
  TODO investigate: will it work if there are no spaces above what's been played?
  TODO investigate: will it work if there are no valid plays on the board? (empty list)
  TODO ensure we can start at existing letters (rather, just below or right)
  TODO ensure we are not passing through bad starts
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
    plays = for start_yx <- start_yxs, word_start <- word_starts, direction <- [:y, :x] do
      create(game, %{direction: direction, player_key: player_key, start_yx: start_yx, word_start: word_start})
    end
    # no need to consider invalid plays
    plays = plays |> Enum.filter(fn(%{valid: v}) -> v == true end)
    # extend via reducer
    plays
    # this crazy self-recursive reducer will allow us to extend for all tiles in tray
    |> Enum.reduce(plays, fn(play, acc) -> append_remaining(game, play, acc) end)
    # now verify all returned plays are fully valid, and score them
    |> Enum.map(fn(play) -> GamePlay.verify_final_play(play, game) end)
    # now strip all invlid plays
    |> Enum.filter(fn(%{valid: v}) -> v == true end)
    # now sort by score (why not?) [decsending]
    |> Enum.sort(fn(%{score: s1}, %{score: s2}) -> s1 > s2 end)
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
  def append_remaining(%GameInstance{} = _game, %GamePlay{valid: false} = _play_start, plays), do: plays
  def append_remaining(%GameInstance{} = _game, %GamePlay{tiles_in_tray: []} = play_start, plays) do
    [play_start | plays]
  end
  def append_remaining(%GameInstance{} = game, %GamePlay{tiles_in_tray: tiles_in_tray} = play_start, plays) do
    # add a "next_play" for each tile left in the tray
    next_plays = tiles_in_tray
                 |> Enum.map(fn(tile) -> append_tile(game, play_start, tile) end)
                 |> Enum.filter(fn(%{valid: v}) -> v == true end)

    case Enum.empty?(next_plays) do
      true -> plays
      false ->
        # add all of these next_plays to the list of all plays
        plays = plays ++ next_plays
        # recursively "reduce" to add next next_plays for each tile left in the tray
        next_plays
        |> Enum.reduce(
          plays,
          fn(play, acc) -> append_remaining(game, play, acc) end
        )
    end
  end

  @doc """
  Append a single tile to a GamePlay (following in the same direction)
  NOTE assumes the tiles_in_tray has already been removed
  """
  def append_tile(
    %GameInstance{} = game,
    %GamePlay{
      board_next: board_next,
      tiles_in_tray: tiles_in_tray,
      tiles_in_play: tiles_in_play,
      errors: [],
    } = play,
    %{letter: _letter} = tile
  ) do
    [y, x] = next_unplayed_yx(play)
    {tiles_from_tray, tiles_in_tray} = GameTiles.take_from_tray(tiles_in_tray, [tile])
    tile_to_play = tiles_from_tray |> List.first() |> Map.merge(%{y: y, x: x})
    case is_valid_tile_for_play?(tile_to_play, board_next) do
      true ->
        # we are extending this play, into a new play with this new tile on it
        #   GOTCHA look out - we will be re-creating the final "play"
        #   with just the letters_yx
        tiles_in_play = tiles_in_play ++ [tile_to_play]
        letters_yx = tiles_in_play |> Enum.map(fn(%{letter: l, y: y, x: x}) -> [l, y, x] end)
        play |> Map.merge(%{
          board_next: board_next |> GameBoard.add_letters([tile_to_play]),
          tiles_in_tray: tiles_in_tray,
          tiles_in_play: tiles_in_play,
          letters_yx: letters_yx,
        })
        |> GamePlay.assign_words(game)
        |> GamePlay.verify_words_are_at_least_partial(game)
        |> GamePlay.verify_no_errors()
        |> GamePlay.assign_score(game)
      false ->
        play |> Map.merge(%{
          errors: ["Unable to append_tile"],
          valid: false,
        })
    end
  end
  def append_tile(
    %GameInstance{},
    %GamePlay{} = play,
    %{} = tile
  ), do: play


  @doc """
  Is about-to-be-played tile a valid tile for the board?
  """
  def is_valid_tile_for_play?(%{letter: letter, x: x, y: y}, board) do
    {total_y, total_x, _center_y, _center_x} = GameBoard.measure(board)
    is_bitstring(letter) &&
      y >= 0 && y < total_y &&
      x >= 0 && x < total_x &&
      !GameBoard.played?(board, y, x)
  end

  @doc """
  Find the next playable y+x in a direction (skipping over already played)
  """
  def next_unplayed_yx(%GamePlay{board_next: board, tiles_in_play: tiles_in_play, direction: :y}) do
    {total_y, _total_x, _center_y, _center_x} = GameBoard.measure(board)
    last_tile = tiles_in_play
                |> Enum.sort(fn(%{y: y1}, %{y: y2}) -> y1 < y2 end)
                |> List.last()
    y = last_tile.y
        |> Range.new(total_y)
        |> Enum.filter(fn(y) -> y < total_y and y > last_tile.y end)
        |> Enum.filter(fn(y) -> !GameBoard.played?(board, y, last_tile.x) end)
        |> List.first()
    [y, last_tile.x]
  end
  def next_unplayed_yx(%GamePlay{board_next: board, tiles_in_play: tiles_in_play, direction: :x}) do
    {_total_y, total_x, _center_y, _center_x} = GameBoard.measure(board)
    last_tile = tiles_in_play
                |> Enum.sort(fn(%{x: x1}, %{x: x2}) -> x1 < x2 end)
                |> List.last()
    x = last_tile.x
        |> Range.new(total_x)
        |> Enum.filter(fn(x) -> x < total_x and x > last_tile.x end)
        |> Enum.filter(fn(x) -> !GameBoard.played?(board, last_tile.y, x) end)
        |> List.first()
    [last_tile.y, x]
  end

end

