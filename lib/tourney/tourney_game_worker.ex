defmodule Wordza.TourneyGameWorker do
  @moduledoc """
  Auto-Play a Game - this is a Worker for the TourneyGameSupervisor
  (called by swarm)
  - start a game
  - run each move
  - log the game
  - stop the game
  - then end gracefully
  """
  require Logger
  use GenServer
  @loop_delay 1

  ### Client API

  @doc """
  Start and run a game until complete, then return
  """
  def play_game(%Wordza.TourneyGameConfig{} = conf) do
    {:ok, pid} = start_link(conf)
    conf = pid |> complete_game()
    pid |> shutdown()
    pid |> stop()
    {:ok, conf}
  end
  def play_game_bg(%Wordza.TourneyGameConfig{} = conf) do
    {:ok, pid} = start_link(conf)
    pid |> complete_game_bg()
    conf = pid |> get()
    {:ok, conf}
  end


  @doc """
  Easy access to start up the server
  """
  def start_link(%Wordza.TourneyGameConfig{} = conf) do
    GenServer.start_link(
      __MODULE__,
      conf,
      [
        timeout: 30_000, # 30 seconds to init or die
      ]
    )
  end
  def start_link(%{} = conf) do
    conf |> Wordza.TourneyGameConfig.create() |> start_link()
  end

  @doc """
  Get the state of the current process
  """
  def get(pid), do: GenServer.call(pid, {:get})

  @doc """
  Take the next turn and return state
  """
  def next(pid), do: GenServer.call(pid, {:next})

  @doc """
  Complete the whole game and return state
  """
  def complete_game(pid) do
    GenServer.call(pid, {:complete_game})
  end

  @doc """
  Complete the whole game in the background
  """
  def complete_game_bg(pid), do: GenServer.cast(pid, {:complete_game_bg})

  @doc """
  Shutdown this TourneyGameWorker process
  """
  def shutdown(pid) do
    case Process.alive?(pid) do
      true -> GenServer.call(pid, {:shutdown})
      false ->
        Logger.warn "TourneyGameWorker.shutdown abort - already dead"
        :dead
    end
  end

  @doc """
  Stop this TourneyGameWorker process
  """
  def stop(:dead), do: :dead
  def stop(pid) do
    case Process.alive?(pid) do
      true -> GenServer.stop(pid)
      false ->
        Logger.warn "TourneyGameWorker.stop abort - already dead"
        :ok
    end
  end

  ### Server API

  def init(%Wordza.TourneyGameConfig{
    type: type,
    player_1_id: player_1_id,
    player_2_id: player_2_id,
  } = conf) do
    # Logger.info "TourneyGameWorker.init starting game: #{inspect(type)}, #{inspect(player_1_id)}, #{inspect(player_2_id)}"

    # start the game
    {:ok, game_pid} = Wordza.Game.start_link(type, player_1_id, player_2_id)
    # update state with game_pid
    state = Map.merge(conf, %{game_pid: game_pid, tourney_worker_pid: self()})
    # rely on :timeout to schedule "next"
    # return state
    {:ok, state}
  end

  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:next}, _from, state) do
    {:ok, state} = Wordza.TourneyAutoplayer.next(state)
    {:reply, state, state}
  end
  def handle_call({:complete_game}, _from, state) do
    {:ok, state} = Wordza.TourneyAutoplayer.complete(state)
    # TODO handle things after game has completed
    {:reply, state, state}
  end

  ### Server API for SWARM
  # see https://github.com/bitwalker/swarm

  def handle_call({:swarm, :begin_handoff}, _from, {delay, count}) do
    {:reply, {:resume, {delay, count}}, {delay, count}}
  end
  def handle_call(:ping, _from, state) do
    {:reply, {:pong, self()}, state}
  end
  def handle_call({:shutdown}, _from, state) do
    state |> oncomplete_tourney_scheduler_pid()
    {:reply, state, state}
  end

  def handle_cast({:swarm, :end_handoff, {delay, count}}, {_, _}) do
    {:noreply, {delay, count}}
  end

  # background process until complete
  def handle_cast({:complete_game_bg}, state) do
    Process.send_after(self(), :loop_until_complete, @loop_delay)
    {:noreply, state}
  end

  # def handle_cast(_, state) do
  #   Logger.warn "janky cast"
  #   {:noreply, state}
  # end

  # background process until complete
  def handle_cast({:complete_game_bg}, state) do
    Process.send_after(self(), :loop_until_complete, @loop_delay)
    {:noreply, state}
  end
  # loop until complete
  def handle_info(:loop_until_complete, %{done: true} = state) do
    shutdown(self())
    stop(self())
    {:noreply, state}
  end
  def handle_info(:loop_until_complete, state) do
    # NOTE: we could just use complete here
    #   but want to send more messages and see how bad it is
    {:ok, state} = Wordza.TourneyAutoplayer.next(state)
    Process.send_after(self(), :loop_until_complete, @loop_delay)
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    Logger.info "TourneyGameWorker.handle_info :timeout #{inspect(state)}"
    Process.send_after(self(), :timeout, 10)
    {:ok, state} = Wordza.TourneyAutoplayer.next(state)
    {:noreply, state}
  end

  # def handle_info(:timeout, {delay, count}) do
  #   Process.send_after(self(), :timeout, delay)
  #   {:noreply, {delay, count + 1}}
  # end

  # this message is sent when this process should die
  # because it's being moved, use this as an opportunity
  # to clean up
  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end
  def handle_info(msg, state) do
    Logger.info "TourneyGameWorker - unknown info #{inspect(msg)}"
    {:noreply, state}
  end

  @doc """
  Send a notification message upon completion of a game
  """
  def oncomplete_tourney_scheduler_pid(%{tourney_scheduler_pid: pid} = state) when is_pid(pid) do
    Logger.info "TourneyGameWorker.oncomplete_tourney_scheduler_pid #{inspect(state)}"
    case (is_pid(pid) && Process.alive?(pid)) do
      true ->
        Wordza.TourneyScheduleWorker.tourney_done(pid)
        nil
      false ->
        Logger.warn "TourneyGameWorker.oncomplete_tourney_scheduler_pid unable to notify dead process: #{inspect(pid)}"
    end
  end
  def oncomplete_tourney_scheduler_pid(_state), do: nil

  @doc """
  Cleanup on exit - will Stop the Game process with a :normal done message
  """
  def terminate(reason, state) do
    GenServer.stop(state.game_pid, reason) # kill Game
    :ok
  end

end
