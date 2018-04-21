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

  ### Client API

  @doc """
  Start and run a game until complete, then return
  """
  def play_game(%Wordza.TourneyGameConfig{} = conf) do
    {:ok, pid} = start_link(conf)
    conf = pid |> complete()
    pid |> done()
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
  def complete(pid), do: GenServer.call(pid, {:complete})

  @doc """
  Stop the TourneyGameWorker tprocess with a :normal done message
  terminate() will Stop the Game process with a :normal done message
  """
  def done(pid), do: GenServer.stop(pid, :normal)

  ### Server API

  def init(%Wordza.TourneyGameConfig{
    type: type,
    player_1_id: player_1_id,
    player_2_id: player_2_id,
  } = conf) do
    # start the game
    {:ok, game_pid} = Wordza.Game.start_link(type, player_1_id, player_2_id)
    # update state with game_pid
    state = Map.merge(conf, %{game_pid: game_pid})
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
  def handle_call({:complete}, _from, state) do
    {:ok, state} = Wordza.TourneyAutoplayer.complete(state)
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

  def handle_cast({:swarm, :end_handoff, {delay, count}}, {_, _}) do
    {:noreply, {delay, count}}
  end
  def handle_cast(_, state) do
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
  def handle_info(_, state), do: {:noreply, state}

  @doc """
  Cleanup on exit - will Stop the Game process with a :normal done message
  """
  def terminate(reason, state) do
    #IO.inspect "stopping #{inspect self()} on #{Node.self}"
    GenServer.stop(state.game_pid, reason) # kill Game
    :ok
  end

end
