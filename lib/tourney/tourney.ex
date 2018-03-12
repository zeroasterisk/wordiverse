defmodule Wordza.Tourney do
  @moduledoc """
  Setup a Tournement to manage several games

  * create a number of games in the lobby
  * create an Autoplayer for each game, which will run until complete
  * collect the results of each game, and centralize those results
  * report on the results
  """
  require Logger
  use GenServer
  alias Wordza.Game
  alias Wordza.Autoplayer

  ### Client API

  @doc """
  Easy access to start up the server

  On new:
    returns {:ok, pid}
  On repeat:
    returns {:error, {:already_started, #PID<0.248.0>}}
  """
  def start_link(type, player_1_id, player_2_id, number_of_games, number_in_parallel) do
    out = GenServer.start_link(__MODULE__, %{
      id: DateTime.utc_now() |> DateTime.to_unix(),
      type: type,
      player_1_id: player_1_id,
      player_2_id: player_2_id,
      number_of_games: number_of_games,
      number_in_parallel: number_in_parallel,
    }, [])
    out |> start_link_nice()
  end
  def start_link_nice({:ok, pid}), do: {:ok, pid}
  def start_link_nice({:error, {:already_started, pid}}), do: {:ok, pid}
  def start_link_nice({:error, err}), do: {:error, err}

  ### Server API
  def init(%{
      id: id,
      type: type,
      player_1_id: player_1_id,
      player_2_id: player_2_id,
      number_of_games: number_of_games,
      number_in_parallel: number_in_parallel,
  }) do
    Wordza.Dictionary.start_link(type)
    schedule_loop()
    {:ok, %{
      id: id,
      type: type,
      player_1_id: player_1_id,
      player_2_id: player_2_id,
      # eventually this would be configurable
      player_1_module: Wordza.BotAlec,
      player_2_module: Wordza.BotAlec,
      number_of_games: number_of_games,
      number_in_parallel: number_in_parallel,
      # internal configurations
      number_started: 0,
      running_game_ids: [],
      completed_game_ids: [],
      logged_game_ids: [],
    }}
  end

  def handle_info(:loop, state) do
    case loop_process(state) do
      {:done, state} ->
        # all the way done, whoo hoo!
        Logger.info "DONE"
        {:reply, {:done, state}, state}
      {:error, err} ->
        # super-sad, we are broken!
        Logger.info "ERROR"
        {:reply, {:error, err}, state}
      {:ok, state} ->
        schedule_loop()
        {:noreply, state}
    end
  end

  defp schedule_loop() do
    Process.send_after(self(), :loop, 1) # In 1 ms
    # TODO review, do we need to delay?
    #              could we just send?
  end

  @doc """
  This is the process/loop cycle, which will keep things going until done.
  """
  def loop_process(%{
    completed_game_ids: completed_game_ids,
    number_of_games: number_of_games,
  } = state) do
    games_left = number_of_games - Enum.count(completed_game_ids)
    case games_left == 0 do
      true -> {:done, state}
      false ->
        # doing a single loop of process
        {:ok,
          state
          # move any "done" games out
          |> loop_process_done()
          # start any "new" games
          |> loop_process_start()
          # TODO log games in bulk (or maybe individually?)
        }
    end
  end

  @doc """
  internal func. will move any "done" running_game_ids -> completed_game_ids
  """
  def loop_process_done(%{
    running_game_ids: running_game_ids,
    completed_game_ids: completed_game_ids,
  } = state) do
    completing_game_ids = running_game_ids
                          |> Enum.filter(&Game.game_over?/1)
                          |> MapSet.new
    # Logger.info "loop_process_done #{inspect(completing_game_ids)}/#{inspect(running_game_ids)}"
    completing_game_ids
    |> Enum.each(fn(game_pid) ->
      p1_score = game_pid |> Game.get(:player_1) |> Map.get(:score)
      p2_score = game_pid |> Game.get(:player_2) |> Map.get(:score)
      Logger.info fn() -> "  + done w/ game #{inspect(game_pid)} #{p1_score} vs. #{p2_score}" end

    end)
    state |> Map.merge(%{
      running_game_ids: running_game_ids |> MapSet.new |> MapSet.difference(completing_game_ids) |> MapSet.to_list,
      completed_game_ids: completed_game_ids |> MapSet.new |> MapSet.union(completing_game_ids) |> MapSet.to_list,
    })
  end

  @doc """
  internal func. will trigger a "start" until we have the desired number of games running
  """
  def loop_process_start(%{
    number_in_parallel: number_in_parallel,
    running_game_ids: running_game_ids,
  } = state) do
    start_games = number_in_parallel - Enum.count(running_game_ids)
    case start_games == 0 do
      true -> state
      false -> state |> start_game() |> loop_process_start()
    end
  end

  @doc """
  internal func. will start new game and put into state.running_game_ids
  - Create new Game
  - Create Autoplayer
  - Start Autoplayer to complete game
  """
  def start_game(%{
    type: type,
    player_1_id: player_1_id,
    player_2_id: player_2_id,
    player_1_module: player_1_module,
    player_2_module: player_2_module,
    running_game_ids: running_game_ids,
  } = state) do
    {:ok, game_pid} = Game.start_link(type, player_1_id, player_2_id)
    {:ok, auto_pid} = Autoplayer.start_link(game_pid, player_1_module, player_2_module)
    :ok = Autoplayer.play_game_background(auto_pid)
    Logger.info fn() -> "  + started game #{inspect(game_pid)} as auto #{inspect(auto_pid)}" end
    state |> Map.merge(%{running_game_ids: [game_pid | running_game_ids]})
  end

end
