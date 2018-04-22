defmodule Wordza.TourneyScheduler do
  @moduledoc """
  Manage a Tournement - scheduling out several games

  This is bit like a ghetto pooly/poolboy,
  But it functions as a trickler/nibbler instead
  with @number_in_parallel slots available
  and it should run until all @number_of_games are complete
  while looping, if a slot is available, we start a new game in it

  No GenServer, just simple passthrough functions
  """
  require Logger
  alias Wordza.Game

  @doc """
  Take the next turn in a game and return state
  or return state with done=true if game is over
  """
  def next(%Wordza.TourneyScheduleConfig{done: true} = state) do
    # Logger.info "TourneyScheduler done=true"
  end
  def next(%Wordza.TourneyScheduleConfig{number_left: 0} = state) do
    # Logger.info "TourneyScheduler number_left=0"
  end
  def next(%Wordza.TourneyScheduleConfig{number_of_games: 0} = state) do
    Logger.info "TourneyScheduler number_of_games=0"
  end
  def next(%Wordza.TourneyScheduleConfig{
    number_of_games: number_of_games,
    number_in_parallel: number_in_parallel,
  } = state) do
    # Logger.info "TourneyScheduler number_of_games=#{number_of_games} number_in_parallel=#{number_in_parallel}"
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
    number_of_slots = number_in_parallel - running
    number_to_start = total - completed - running
    min(number_of_slots, number_to_start)
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
    tourney_scheduler_pid: tourney_scheduler_pid,
  } = state) do
    conf = %Wordza.TourneyGameConfig{
      type: type,
      player_1_id: player_1_id,
      player_2_id: player_2_id,
      player_1_module: player_1_module,
      player_2_module: player_2_module,
      tourney_scheduler_pid: tourney_scheduler_pid,
    }
    # Currently this is just me manually starting a TourneyGameWorker
    # ideally this will change to spawn.register (I think)
    # TODO truthfully, we could offload the messaging to the TourneyGameWorker
    #   the worker registers itself with the Scheduler
    #   the worker completes the game (async)
    #   the worker de-registers itself with the Scheduler
    #   (this is even more like a pool)
    {:ok, conf} = Wordza.TourneyGameWorker.play_game_bg(conf)
    # consider Process.monitor (from the Supervisor for the Worker)?
    # consider Process.monitor (from the Worker for the Game)?
    game_pid = conf.game_pid
    # Logger.info "  + TourneyScheduler started game #{inspect(game_pid)}"
    state |> Map.merge(%{
      running_game_ids: [game_pid | running_game_ids]
    }) |> Wordza.TourneyScheduleConfig.calc()
  end

  def tourney_done(%Wordza.TourneyScheduleConfig{number_completed: number_completed} = state) do
    # TODO work on getting the game_pid out of the running_game_ids
    #   we have to be able to monitor the status of each game
    #   ideally by having the tourney_worker "callback" on exit (like it is)
    state |> Map.merge(%{
      number_completed: number_completed + 1,
      # running_game_ids: running_game_ids |> Enum.filter(fn(p) -> p == game_pid end)
    })
    {:ok, state}
  end

end
