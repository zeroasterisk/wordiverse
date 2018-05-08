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
  alias Wordza.TourneyGameConfig
  alias Wordza.TourneyGameCore
  alias Wordza.TourneyScheduleWorker
  alias Wordza.TourneyScheduleConfig
  alias Wordza.GameInstance
  alias Wordza.GameLog
  alias Wordza.Game
  alias Wordza.Dictionary
  use GenServer
  @loop_delay 1

  ### Client API

  @doc """
  Start and run a game until complete, then return
  """
  def play_game(%TourneyGameConfig{} = conf) do
    {:ok, pid} = start_link(conf)
    conf = pid |> complete_game()
    pid |> stop()
    {:ok, conf}
  end
  def play_game_bg(%TourneyGameConfig{} = conf) do
    {:ok, pid} = start_link(conf)
    pid |> complete_game_bg()
    conf = pid |> get()
    {:ok, conf}
  end


  @doc """
  Easy access to start up the server
  """
  def start_link(%TourneyGameConfig{} = conf) do
    GenServer.start_link(
      __MODULE__,
      conf,
      [
        timeout: 30_000, # 30 seconds to init or die
      ]
    )
  end
  def start_link(%{} = conf) do
    conf |> TourneyGameConfig.create() |> start_link()
  end

  @doc """
  Get the state of the current process
  """
  def get(name), do: name |> via_tuple |> GenServer.call({:get})

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

  def init(%TourneyGameConfig{
    type: type,
    player_1_id: player_1_id,
    player_2_id: player_2_id,
  } = conf) do
    dictionary_name = GameInstance.build_game_name(type)
    # IO.puts "---------------------------"
    # IO.puts "TourneyGameWorker.init starting dictionary: #{inspect(type)} #{inspect(dictionary_name)}"
    # create a cloned dictionary
    {:ok, dictionary_pid} = Dictionary.start_link({:clone, type}, dictionary_name)
    # IO.puts "TourneyGameWorker.init starting game: #{inspect(type)}, #{inspect(player_1_id)}, #{inspect(player_2_id)}"
    # start the game - linked to "monitor" it's messages here
    {:ok, game_pid} = Game.start_link(type, player_1_id, player_2_id, dictionary_name)
    # update state with game_pid
    state = Map.merge(conf, %{game_pid: game_pid, tourney_worker_pid: self()})

    # rely on human intervention to trigger :next or complete synchronously
    # return state
    {:ok, state}
  end

  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:next}, _from, state) do
    {:ok, state} = TourneyGameCore.next(state)
    {:reply, state, state}
  end
  def handle_call({:complete_game}, _from, state) do
    {:ok, state} = TourneyGameCore.complete(state)
    {:reply, state, state}
  end

  # background process until complete
  def handle_cast({:complete_game_bg}, state) do
    Process.send_after(self(), :loop_until_complete, @loop_delay)
    {:noreply, state}
  end

  # loop stopped (pause)
  def handle_info(:loop_until_complete, %{enable_loop: false} = state) do
    {:noreply, state}
  end
  # loop until complete
  def handle_info(:loop_until_complete, state) do
    state = run_next_step(state)
    Process.send_after(self(), :loop_until_complete, @loop_delay)
    {:noreply, state}
  end

  ### Server API for SWARM
  # see https://github.com/bitwalker/swarm

  # def handle_call({:swarm, :begin_handoff}, _from, {delay, count}) do
  #   {:reply, {:resume, {delay, count}}, {delay, count}}
  # end
  # def handle_call(:ping, _from, state) do
  #   {:reply, {:pong, self()}, state}
  # end
  #
  # def handle_cast({:swarm, :end_handoff, {delay, count}}, {_, _}) do
  #   {:noreply, {delay, count}}
  # end
  #
  #
  # def handle_info(:timeout, state) do
  #   Logger.warn "TourneyGameWorker.handle_info :timeout #{inspect(state)}"
  #   Process.send_after(self(), :timeout, 10)
  #   {:ok, state} = TourneyGameCore.next(state)
  #   {:noreply, state}
  # end

  # def handle_info(:timeout, {delay, count}) do
  #   Process.send_after(self(), :timeout, delay)
  #   {:noreply, {delay, count + 1}}
  # end

  # this message is sent when this process should die
  # because it's being moved, use this as an opportunity
  # to clean up
  def handle_info({:swarm, :die}, state) do
    {:stop, :swarm_die, state}
  end
  def handle_info(msg, state) do
    Logger.warn "TourneyGameWorker - unknown info #{inspect(msg)}"
    {:noreply, state}
  end

  @doc """
  Cleanup when the Game is completed successfully
  """
  def onsuccess(state) do
    # Logger.info "TourneyGameWorker.onsuccess done #{inspect(state)} #{inspect(self())}"
    state
    |> tourney_done_logger()
    |> tourney_done_in_scheduler()
    |> unregister_worker_in_scheduler(:normal)
    |> terminate_game(:normal)
    :ok
  end
  @doc """
  Cleanup on exit - will Stop the Game process with a :normal done message
  """
  def terminate(reason, state) do
    # Logger.warn "TourneyGameWorker.terminate #{inspect(reason)} #{inspect(state)} #{inspect(self())}"
    state
    |> unregister_worker_in_scheduler(reason)
    |> terminate_game(reason)
    :ok
  end


  ######################
  ## Internal Private ##
  ######################


  @doc """
  Take the next turn in a game and return state
  or return state with done=true if game is over
  """
  def run_next_step(%TourneyGameConfig{done: true} = state) do
    # Logger.info "TourneyGameWorker.loop(info) about to stop self"
    onsuccess(state)
    GenServer.stop(self())
    state
  end
  def run_next_step(%TourneyGameConfig{} = state) do
    {:ok, state} = TourneyGameCore.next(state)
    state
  end

  def unregister_worker_in_scheduler(%{tourney_scheduler_pid: pid, tourney_worker_pid: self_pid} = state, reason) when is_pid(pid) do
    case Process.alive?(pid) do
      true ->
        # Logger.info "TourneyGameWorker.unregister_scheduler about to call unregister_worker"
        TourneyScheduleWorker.unregister_worker(pid, self_pid)
        state
      false ->
        Logger.warn "TourneyGameWorker.unregister_scheduler #{reason} abort - already dead"
        state
    end
  end
  def unregister_worker_in_scheduler(%{tourney_scheduler_pid: pid, type: :mock} = state, _reason) when is_nil(pid) do
    # testing, this is fine
    state
  end
  def unregister_worker_in_scheduler(%{tourney_scheduler_pid: pid} = state, _reason) when is_nil(pid) do
    # we may allow this in the future, but for now, this seems wonky
    Logger.warn "TourneyGameWorker.unregister_scheduler can not unregister_worker, pid is nil in #{inspect(state)}"
    state
  end

  def terminate_game(%TourneyGameConfig{game_pid: pid} = _state, reason) do
    case Process.alive?(pid) do
      true ->
        # Logger.info "TourneyGameWorker.terminate_game about to stop game"
        GenServer.stop(pid, reason)
      false ->
        Logger.warn "TourneyGameWorker.terminate_game abort - already dead"
        :dead
    end
  end

  def tourney_done_in_scheduler(%{tourney_scheduler_pid: pid, tourney_worker_pid: self_pid} = state) when is_pid(pid) do
    case Process.alive?(pid) do
      true ->
        # Logger.info "TourneyGameWorker.tourney_done_in_scheduler about to call tourney_done"
        TourneyScheduleWorker.tourney_done(pid, self_pid)
        state
      false ->
        Logger.warn "TourneyGameWorker.tourney_done_in_scheduler abort - already dead"
        state
    end
  end
  def tourney_done_in_scheduler(%{type: :mock} = state) do
    # testing, this is fine
    state
  end
  def tourney_done_in_scheduler(state) do
    # we may allow this in the future, but for now, this seems wonky
    Logger.warn "TourneyGameWorker.tourney_done_in_scheduler abort - invalid state #{inspect(state)}"
    state
  end

  def tourney_done_logger(%TourneyGameConfig{game_pid: pid} = state) do
    case Process.alive?(pid) do
      true ->
        # Logger.info "TourneyGameWorker.tourney_done_logger about to log game"
        Game.get(pid, :full) |> GameLog.write(state)
      false ->
        Logger.warn "TourneyGameWorker.tourney_done_logger abort - game is dead #{inspect(pid)}"
    end
    state
  end

  # Fancy name <-> pid refernce library `gproc`
  defp via_tuple(pid) when is_pid(pid), do: pid
  defp via_tuple(name) when is_atom(name), do: name
  defp via_tuple(name) do
    {:via, :gproc, {:n, :l, {:wordza_tourney_game_worker, name}}}
  end

end
