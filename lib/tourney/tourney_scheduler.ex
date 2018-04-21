defmodule Wordza.TourneyScheduler do
  @moduledoc """
  Manage a Tournement - scheduling out several games

  No GenServer, just simple passthrough functions
  """
  require Logger
  alias Wordza.Game

  @doc """
  Take the next turn in a game and return state
  or return state with done=true if game is over
  """
  def next(%Wordza.TourneyScheduleConfig{done: true} = state) do
  end
  def next(%Wordza.TourneyScheduleConfig{number_left: 0} = state) do
  end
  def next(%Wordza.TourneyScheduleConfig{number_of_games: 0} = state) do
  end
  def next(%Wordza.TourneyScheduleConfig{
    number_of_games: number_of_games,
    number_in_parallel: number_in_parallel,
  } = state) do
    number_to_start = next_get_spawn_count(state)
    state = next_spawn_games(state, number_to_start)
    {:ok, state}
  end

  @doc """
  spawn this many games
  """
  def next_get_spawn_count(%Wordza.TourneyScheduleConfig{
    number_of_games: total,
    number_running: running,
    number_completed: completed,
    number_in_parallel: number_in_parallel,
  } = state) do
    # we still need to start: total - completed - running
    number_to_start = total - completed - running
    min(number_in_parallel, number_to_start)
  end

  @doc """
  spawn as many games as requested in number_to_start
  """
  def next_spawn_games(%Wordza.TourneyScheduleConfig{} = state, 0 = _number_to_start) do
    state
  end
  def next_spawn_games(%Wordza.TourneyScheduleConfig{} = state, number_to_start) do
    state |> next_spawn_game() |> next_spawn_games(number_to_start - 1)
  end

  @doc """
  spawn a single game, and update state to reflect this

  TODO reconfigure to Supervisor triggered
  TODO reconfigure to Spawn
  """
  def next_spawn_game(%Wordza.TourneyScheduleConfig{
    type: type,
    player_1_id: player_1_id,
    player_2_id: player_2_id,
    player_1_module: player_1_module,
    player_2_module: player_2_module,
    running_game_ids: running_game_ids,
  } = state) do
    conf = %Wordza.TourneyGameConfig{
      type: type,
      player_1_id: player_1_id,
      player_2_id: player_2_id,
      player_1_module: player_1_module,
      player_2_module: player_2_module,
    }
    {:ok, conf} = Wordza.TourneyGameWorker.play_game(conf)
    game_pid = conf.game_pid
    Logger.info fn() -> "  + TourneyScheduler started game #{inspect(game_pid)}" end
    state |> Map.merge(%{
      running_game_ids: [game_pid | running_game_ids]
    }) |> Wordza.TourneyScheduleConfig.calc()
  end

end
