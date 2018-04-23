defmodule Wordza.TourneyScheduleWorker do
  @moduledoc """
  Manage a Tournement of Games

  this is a Worker for the TourneyGameSupervisor
  (called by swarm)

  - maintain a config for the Tournement
  * start/run/complete a number of TourneyGames in parallel
  * TODO update config params
  * TODO report on the results
  """
  require Logger
  use GenServer
  @loop_delay 1

  ### Client API

  @doc """
  Easy access to start up the server
  """
  def start_link(%Wordza.TourneyScheduleConfig{} = conf) do
    GenServer.start_link(
      __MODULE__,
      conf,
      [
        timeout: 30_000, # 30 seconds to init or die
      ]
    )
  end
  def start_link(%{} = conf) do
    conf |> Wordza.TourneyScheduleConfig.create() |> start_link()
  end
  def start_link(:mock_test_small) do
    Wordza.Dictionary.start_link(:mock)
    {:ok, pid} = :mock
                 |> Wordza.TourneyScheduleConfig.create()
                 |> Map.merge(%{
                   name: :basic_test_small,
                   number_of_games: 10,
                   number_in_parallel: 2,
                 })
                 |> start_link()
    # pid |> complete()
    {:ok, pid}
  end
  def start_link(:scrabble_test_small) do
    Wordza.Dictionary.start_link(:scrabble)
    {:ok, pid} = :scrabble
                 |> Wordza.TourneyScheduleConfig.create()
                 |> Map.merge(%{
                   name: :basic_test_small,
                   number_of_games: 10,
                   number_in_parallel: 2,
                 })
                 |> start_link()
    # pid |> complete()
    {:ok, pid}
  end
  def start_link(:scrabble_test_large) do
    Wordza.Dictionary.start_link(:scrabble)
    {:ok, pid} = :scrabble
                 |> Wordza.TourneyScheduleConfig.create()
                 |> Map.merge(%{
                   name: :basic_test_small,
                   number_of_games: 10_000,
                   number_in_parallel: 10,
                 })
                 |> start_link()
    # pid |> complete()
    {:ok, pid}
  end

  @doc """
  Get the state of the current process
  """
  def get(pid), do: GenServer.call(pid, {:get})

  @doc """
  Start this process (if loop was disabled)
  Not usually needed, since we auto-play on init
  """
  def play(pid), do: GenServer.call(pid, {:play})

  @doc """
  Pause this process (stops the loop)
  Not usually needed
  """
  def pause(pid), do: GenServer.call(pid, {:pause})

  @doc """
  Take the next step in the loop and return state
  Not usually needed
  """
  def next_step(pid), do: GenServer.call(pid, {:next_step})

  @doc """
  Complete the whole game and return state
  """
  def complete({:ok, pid}), do: GenServer.call(pid, {:complete})
  def complete(pid), do: GenServer.call(pid, {:complete})

  @doc """
  Register a TourneyGameWorker process as running_tourney_pids
  """
  def register_worker(pid, tourney_pid), do: GenServer.call(pid, {:register_worker, tourney_pid})
  def register_worker({pid, tourney_pid}), do: GenServer.call(pid, {:register_worker, tourney_pid})

  @doc """
  Register a TourneyGameWorker process as running_tourney_pids
  """
  def unregister_worker(pid, tourney_pid), do: GenServer.call(pid, {:unregister_worker, tourney_pid})
  def unregister_worker({pid, tourney_pid}), do: GenServer.call(pid, {:unregister_worker, tourney_pid})

  @doc """
  Get notified that a Tournement Worker is done (adds to number_completed)
  TODO consider tracking tourney_pid or game_pid ? maybe not needed since we will rely on logs
  """
  def tourney_done(pid), do: GenServer.call(pid, {:tourney_done})
  def tourney_done(pid, _tourney_pid), do: GenServer.call(pid, {:tourney_done})

  ### Server API

  def init(%Wordza.TourneyScheduleConfig{} = conf) do
    # autostart loop (if disabled, it wont do anything)
    Process.send_after(self(), :loop_until_complete, @loop_delay)
    {:ok, conf |> Map.merge(%{tourney_scheduler_pid: self()})}
  end

  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:play}, _from, state) do
    # Logger.info "handle_call play from ScheduleWorker #{inspect(self())}"
    state = state |> Map.merge(%{enable_loop: true})
    {:reply, state, state}
  end
  def handle_call({:pause}, _from, state) do
    # Logger.info "handle_call pause from ScheduleWorker #{inspect(self())}"
    state = state |> Map.merge(%{enable_loop: false})
    {:reply, state, state}
  end

  # background process until complete
  def handle_call({:complete}, _from, state) do
    Process.send_after(self(), :loop_until_complete, @loop_delay)
    {:reply, state, state}
  end
  # register_worker (running_tourney_pids add - this is normally done in next())
  def handle_call({:register_worker, tourney_pid}, _from, state) do
    state = state
            |> register_running_tourney_id(tourney_pid)
    {:reply, state, state}
  end
  # unregister_worker (running_tourney_pids remove)
  def handle_call({:unregister_worker, tourney_pid}, _from, state) do
    state = state
            |> unregister_running_tourney_id(tourney_pid)
    # Logger.info "handle_call unregister_worker (removed #{inspect(tourney_pid)}) (now #{inspect(state.running_tourney_pids)})"
    {:reply, state, state}
  end
  # log a tourney as completed
  #   (used in conjuntion with unregister_worker - but this marks as complete)
  def handle_call({:tourney_done}, _from, %{number_completed: number_completed} = state) do
    state = state
            |> Map.merge(%{number_completed: (number_completed + 1)})
            |> Wordza.TourneyScheduleConfig.calc()
    # Logger.info "handle_call tourney_done (old #{number_completed}) (new #{state.number_completed})"
    {:reply, state, state}
  end
  # useful for debugging "steps" in the main loop
  def handle_call({:next_step}, _from, state) do
    # Logger.info "handle_call next_step from ScheduleWorker #{inspect(self())}"
    state = run_next_step(state)
    {:reply, state, state}
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
  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    # I want this to happen - if so, we could monitor the close of a downstream process and cleanup
    Logger.warn "TourneyScheduleWorker - got a DOWN #{inspect(reason)} #{inspect(ref)} #{inspect(pid)}"
    {:noreply, state}
  end
  def handle_info(msg, state) do
    Logger.warn "TourneyScheduleWorker - unknown info #{inspect(msg)}"
    {:noreply, state}
  end


  # TO_DO should we implement swarm API?

  @doc """
  Cleanup on exit - will Stop the Game process with a :normal done message
  """
  def terminate(reason, state) do
    Logger.warn "TourneyScheduleWorker.terminate #{inspect(reason)} #{inspect(state)} #{inspect(self())}"
    :ok
  end


  ######################
  ## Internal Private ##
  ######################


  @doc """
  Take the next turn in a game and return state
  or return state with done=true if game is over
  """
  def run_next_step(%Wordza.TourneyScheduleConfig{done: true} = state) do
    # Logger.info "TourneyScheduleWorker done=true"
    state
  end
  def run_next_step(%Wordza.TourneyScheduleConfig{number_left: 0} = state) do
    # Logger.info "TourneyScheduleWorker number_left=0"
    state
  end
  def run_next_step(%Wordza.TourneyScheduleConfig{number_of_games: 0} = state) do
    # Logger.info "TourneyScheduleWorker number_of_games=0"
    state
  end
  def run_next_step(%Wordza.TourneyScheduleConfig{} = state) do
    # Logger.info "TourneyScheduleWorker next_step #{inspect(state)}"
    number_to_start = next_get_spawn_count(state)
    state
    |> next_spawn_games(number_to_start)
    |> pause_if_done()
  end

  def pause_if_done(%{number_left: 0} = state) do
    # Logger.info "TourneyScheduleWorker loop_until_complete is now done - pausing (could stop)"
    state |> Map.merge(%{enable_loop: false})
  end
  def pause_if_done(state), do: state

  @doc """
  spawn this many games
  """
  def next_get_spawn_count(%Wordza.TourneyScheduleConfig{
    number_of_games: total,
    number_running: running,
    number_completed: completed,
    number_in_parallel: number_in_parallel,
  } = _state) do
    number_of_slots = max(0, number_in_parallel - running)
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
    # Logger.info "  + TourneyScheduleWorker starting game..."
    {:ok, tourney_pid} = Wordza.TourneyGameWorker.start_link(conf)
    # Process.monitor(tourney_pid) # TODO is this doing anything?
    _started = tourney_pid |> Wordza.TourneyGameWorker.complete_game_bg()
    state
    |> register_running_tourney_id(tourney_pid)
  end
  def register_running_tourney_id(%{running_tourney_pids: running_tourney_pids} = state, tourney_pid) do
    running_tourney_pids = running_tourney_pids
                           |> MapSet.new()
                           |> MapSet.put(tourney_pid)
                           |> MapSet.to_list()
    state
    |> Map.merge(%{running_tourney_pids: running_tourney_pids})
    |> Wordza.TourneyScheduleConfig.calc()
  end
  def unregister_running_tourney_id(%{running_tourney_pids: running_tourney_pids} = state, tourney_pid) do
    running_tourney_pids = running_tourney_pids
                           |> MapSet.new()
                           |> MapSet.delete(tourney_pid)
                           |> MapSet.to_list()
    state
    |> Map.merge(%{running_tourney_pids: running_tourney_pids})
    |> Wordza.TourneyScheduleConfig.calc()
  end

end
