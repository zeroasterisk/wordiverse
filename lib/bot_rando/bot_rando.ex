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
  alias Wordza.GamePlay
  alias Wordza.GameBoard

  defstruct [
    tiles_in_tray: nil,
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
    } = _game
  ) do
    {total_y, total_x, center_y, center_x} = board |> GameBoard.measure
    bot = %BotRando{
      tiles_in_tray: tiles_in_tray,
      board: board,
      total_y: total_y,
      total_x: total_x,
      center_y: center_y,
      center_x: center_x,
      first_play?: GameBoard.empty?(board),
    } 
    # TODO build out an Task.await or genserver 
    # to attmpt multiple variations and maintain state across them
    pick_start_yx(bot)

  end

  @doc """

  """

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
    board: board,
  } = bot) do
    # TODO REFACTOR to first get a list of all valid starts, and then random, walk through them to pick (more setup, less cycling & validating)
    [y, x] = bot |> random_yx()
    # if the spot nas nil for a letter, it's valid
    case BotBits.start_yx_possible?(board, y, x) do
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


end

