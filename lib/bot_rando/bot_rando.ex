defmodule Wordza.BotRando do
  @moduledoc """
  Beep Beep, a Bot for Wordza: Randomize forever until anything passes

  This guy is dumb.

  We do not make intelligent choices for letter to try, nor start squares to try

  As with all bots:

      Given a GamePlayer and a GameInstance
      When we run out of time to attempt plays
      Then return a GamePlay which is both valid and the highest scoring
  """
  require Logger
  alias Wordza.BotRando
  alias Wordza.BotBits
  alias Wordza.GameInstance
  alias Wordza.GamePlayer
  # alias Wordza.GamePlay
  alias Wordza.GameBoard
  alias Wordza.PlayAssembler

  defstruct [
    player_key: :player_1, # TODO <-- get from GameInstance
    type: nil,
    tiles_in_tray: nil,
    word_starts: [],
    start_yxs: [],
    plays: [],
    board: nil,
    total_y: nil,
    total_x: nil,
    center_y: nil,
    center_x: nil,
    first_play?: false,
    valid_plays: [],
    # keep track of garbage, so we don't attempt it anymore
    invalid_starts: [],
    invalid_words: [],
    errors: [],
  ]


  @doc """
  Make a legal play, before timeout
  """
  def play(
    %GamePlayer{
      tiles_in_tray: tiles_in_tray,
    } = _player,
    %GameInstance{
      board: board,
    } = game
  ) do
    {total_y, total_x, center_y, center_x} = board |> GameBoard.measure

    %BotRando{
      tiles_in_tray: tiles_in_tray,
      board: board,
      total_y: total_y,
      total_x: total_x,
      center_y: center_y,
      center_x: center_x,
      first_play?: GameBoard.empty?(board),
    }
    |> assign_start_yxs()
    |> assign_word_starts()
    |> assign_all_plays(game)
    |> choose_play()
    # TODO build out an Task.await or genserver
    # to attmpt multiple variations and maintain state across them
    # pick_start_yx(bot)

  end

  defp assign_start_yxs(%BotRando{first_play?: true, center_y: center_y, center_x: center_x} = bot) do
    bot |> Map.merge(%{start_yxs: [center_y, center_x]})
  end
  defp assign_start_yxs(%BotRando{board: board, tiles_in_tray: tiles_in_tray} = bot) do
    bot |> Map.merge(%{start_yxs: BotBits.get_all_start_yx(board, tiles_in_tray)})
  end
  defp assign_word_starts(%BotRando{type: type, tiles_in_tray: tiles_in_tray} = bot) do
    bot |> Map.merge(%{word_starts: BotBits.get_all_word_starts(tiles_in_tray, type)})
  end
  defp assign_all_plays(%BotRando{} = bot, %GameInstance{} = game) do
    bot |> Map.merge(%{plays: PlayAssembler.create_all_plays(game, bot)})
  end
  defp choose_play(%BotRando{plays: plays} = _bot) do
    plays
    |> Enum.filter(fn(%{valid: v}) -> v == true end)
    |> Enum.sort(fn(%{score: y1}, %{score: y2}) -> y1 < y2 end)
    |> List.first()
  end




  @doc """
  Pick an X & Y to start the play

  If this is the first play of the board,
  we can force the play onto the center square

  If not, we want to pick any nil spot, at random, which can connect to an existing letter or word on the board...
  (SUPER RANDOM)
  """
  def pick_start_yx(%BotRando{
    first_play?: true,
    center_y: center_y,
    center_x: center_x,
  }) do
    [center_y, center_x]
  end
  def pick_start_yx(%BotRando{
    tiles_in_tray: tiles_in_tray,
    board: board,
  } = bot) do
    # TODO REFACTOR to first get a list of all valid starts, and then random, walk through them to pick (more setup, less cycling & validating)
    [y, x] = bot |> random_yx()
    # if the spot nas nil for a letter, it's valid
    case BotBits.start_yx_possible?(board, y, x, tiles_in_tray) do
      true -> [y, x]
      _ ->
        # Logger.warn "got a bad Y+X, #{y}+#{x}, recycle"
        pick_start_yx(bot)
    end
  end

  @doc """
  Pick an X & Y to start the play

  If this is the first play of the board,
  we can force the play onto the center square

  If not, we want to pick any nil spot, at random, which can connect to an existing letter or word on the board...
  (SUPER RANDOM)
  """
  def random_yx(%BotRando{total_y: total_y, total_x: total_x}) do
    [
      (:rand.uniform(total_y) - 1),
      (:rand.uniform(total_x) - 1)
    ]
  end

  # @doc """
  # Given a board, set of tile, and a single start_yx
  # Then return a list of all possible plays
  # """
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

