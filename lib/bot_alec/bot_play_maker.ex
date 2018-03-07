defmodule Wordza.BotPlayMaker do
  @moduledoc """
  A set of possibly shared "bits" for all Bots...

  We are going to look at all plays so the bot can pick.
  """
  require Logger
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

  TODO investigate: will it work if you have "?" as a tile?
  TODO investigate: will it work if there are no valid plays on the board? (empty list)
  TODO investigate: ensure we are not passing through bad starts (maybe not an issue)
  """
  def create_all_plays(
    %GameInstance{board: board} = game,
    %{
      player_key: player_key,
      start_yxs: start_yxs,
      word_starts: word_starts,
    } = _bot
  ) do
    # 1. create every combo of
    #    * start_yxs (above played tiles) &
    #    * word_starts (comprised of tiles in tray)
    plays_1 = for start_yx <- start_yxs, word_start <- word_starts, direction <- [:y, :x] do
      create(game, %{direction: direction, player_key: player_key, start_yx: start_yx, word_start: word_start})
    end
    |> Enum.filter(&is_map/1)
    |> Enum.filter(fn(%{valid: v}) -> v == true end)
    # 2. create words "starting" with played tiles
    #    * start_yxs = squares below & right every played tile as start_yx
    #    * word_start = for every letter in tray
    letters_played = board |> GameBoard.to_letter_yx_list()
    start_yxs = for [add_y, add_x] <- [[0, 1], [1, 0]], [_l, y, x] <- letters_played do
      [(y + add_y), (x + add_x)]
    end
    |> Enum.filter(fn([y, x]) -> GameBoard.exists?(board, y, x) end)
    |> Enum.filter(fn([y, x]) -> !GameBoard.played?(board, y, x) end)
    tiles_in_tray = game
                    |> Map.get(player_key)
                    |> Map.get(:tiles_in_tray)
                    |> Enum.map(fn(%{letter: l}) -> [l] end)
                    |> Enum.uniq()
    plays_2 = for start_yx <- start_yxs, word_start <- tiles_in_tray, direction <- [:y, :x] do
      create(game, %{direction: direction, player_key: player_key, start_yx: start_yx, word_start: word_start})
    end
    |> Enum.filter(&is_map/1)
    |> Enum.filter(fn(%{valid: v}) -> v == true end)

    plays = plays_1 ++ plays_2
    # no need to consider invalid plays
    plays = plays |> Enum.filter(fn(%{valid: v}) -> v == true end)
    # extend via reducer
    plays
    # this crazy self-recursive reducer will allow us to extend for all tiles in tray
    |> Enum.reduce(plays, fn(play, acc) -> build_plays_matrix_for_for_each_tile(game, play, acc) end)
    # now verify all returned plays are fully valid, and score them
    |> Enum.map(fn(play) -> GamePlay.verify_final_play(play, game) end)
    # now strip all invlid plays
    |> Enum.filter(fn(%{valid: v}) -> v == true end)
    # now ensure unique by letters_yx (TO-DO: why is this necessary?  optimize reduce)
    |> Enum.uniq_by(fn(%{letters_yx: v}) -> v end)
    # now sort by score - that's the point [descending]
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
  ) when is_list(start_yx) do
    letters_yx = play_word_start_y([], start_yx, word_start)
    player_key |> GamePlay.create(letters_yx, :y) |> GamePlay.verify_start(game)
  end
  def create(
    %GameInstance{} = game,
    %{
      direction: :x,
      player_key: player_key,
      start_yx: start_yx,
      word_start: word_start,
    }
  ) when is_list(start_yx) do
    letters_yx = play_word_start_x([], start_yx, word_start)
    player_key |> GamePlay.create(letters_yx, :x) |> GamePlay.verify_start(game)
  end
  def create(_game, bot) do
    Logger.error fn() -> "BotPlayMaker.create fail - invalid bot input: #{inspect(bot)}" end
    nil
  end

  @doc """
  Lay down tiles for a word_start

  ## Examples

      iex> Wordza.BotPlayMaker.play_word_start_y([], [0, 0], ["a", "l", "l"])
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

      iex> Wordza.BotPlayMaker.play_word_start_x([], [0, 0], ["a", "l", "l"])
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
  def build_plays_matrix_for_for_each_tile(%GameInstance{} = _game, %GamePlay{valid: false} = _play_start, plays), do: plays
  def build_plays_matrix_for_for_each_tile(%GameInstance{} = _game, %GamePlay{tiles_in_tray: []} = play_start, plays) do
    [play_start | plays]
    # now ensure unique by letters_yx (TO-DO: why is this necessary?  optimize reduce)
    |> Enum.uniq_by(fn(%{letters_yx: v}) -> v end)
  end
  def build_plays_matrix_for_for_each_tile(%GameInstance{} = game, %GamePlay{tiles_in_tray: tiles_in_tray} = play_start, plays) do
    # add a "next_play" for each tile left in the tray
    next_plays = tiles_in_tray
                 |> Enum.map(fn(tile) -> build_play_append_tile(game, play_start, tile) end)
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
          fn(play, acc) -> build_plays_matrix_for_for_each_tile(game, play, acc) end
        )
    end
  end

  @doc """
  Generate a new GamePlay by appending a single tile to a GamePlay
  NOTE this will always following in the same direction as the original play
  NOTE assumes the new tile has not been removed from tiles_in_tray
  """
  def build_play_append_tile(
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
        # we are "extending" this play, into a new play with this new tile on it
        # we fake the assign_letters and some early verifies, but do the important stuff here
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
          errors: ["Unable to build_play_append_tile"],
          valid: false,
        })
    end
  end
  def build_play_append_tile(
    %GameInstance{},
    %GamePlay{} = play,
    %{} = _tile
  ), do: play

  @doc """
  Is about-to-be-played tile a valid tile for the board?

  ## Examples

      iex> board = Wordza.GameBoard.create(:mock)
      iex> Wordza.BotPlayMaker.is_valid_tile_for_play?(%{letter: "a", x: 0, y: 0}, board)
      true

      iex> board = Wordza.GameBoard.create(:mock)
      iex> Wordza.BotPlayMaker.is_valid_tile_for_play?(%{letter: nil, x: 0, y: 0}, board)
      false

      iex> board = Wordza.GameBoard.create(:mock)
      iex> Wordza.BotPlayMaker.is_valid_tile_for_play?(%{letter: "a", x: 9, y: 9}, board)
      false
  """
  def is_valid_tile_for_play?(%{letter: letter, x: x, y: y}, board) do
    {total_y, total_x, _center_y, _center_x} = GameBoard.measure(board)
    is_bitstring(letter) &&
      y >= 0 && y < total_y &&
      x >= 0 && x < total_x &&
      !GameBoard.played?(board, y, x)
  end
  def is_valid_tile_for_play?(_, _), do: false

  @doc """
  Find the next playable y+x in a direction (skipping over already played)

  ## Examples

      iex> Wordza.Dictionary.start_link(:mock)
      iex> game = Wordza.GameInstance.create(:mock, :player_1, :player_2)
      iex> played = [%{letter: "A", y: 2, x: 0, value: 1}, %{letter: "L", y: 2, x: 1, value: 1}, %{letter: "L", y: 2, x: 2, value: 1}]
      iex> board = game |> Map.get(:board) |> Wordza.GameBoard.add_letters(played)
      iex> player_1 = game |> Map.get(:player_1) |> Map.merge(%{tiles_in_tray: Wordza.GameTiles.create(:mock_tray)})
      iex> game = game |> Map.merge(%{board: board, player_1: player_1})
      iex> play = Wordza.GamePlay.create(:player_1, [["A", 1, 1]], :y) |> Wordza.GamePlay.verify_start(game)
      iex> Wordza.BotPlayMaker.next_unplayed_yx(play)
      [3, 1]

  """
  def next_unplayed_yx(%GamePlay{board_next: board, tiles_in_play: tiles_in_play, direction: :y, errors: []}) do
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
  def next_unplayed_yx(%GamePlay{board_next: board, tiles_in_play: tiles_in_play, direction: :x, errors: []}) do
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
  def next_unplayed_yx(%GamePlay{errors: errors}) do
    Logger.error("Got an invalid GamePlay for BotPlayMaker.next_unplayed_yx(): #{inspect(errors)}")
    [-1, -1]
  end
  def next_unplayed_yx(play) do
    Logger.error("Got an invalid argument for BotPlayMaker.next_unplayed_yx(): #{inspect(play)}")
    [-1, -1]
  end

end

