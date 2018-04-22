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
  def start_link(:basic_test_small) do
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
  def complete({:ok, pid}), do: GenServer.call(pid, {:complete})
  def complete(pid), do: GenServer.call(pid, {:complete})

  @doc """
  Get notified that a Tournement Worker is done
  """
  def tourney_done(pid) do
    GenServer.call(pid, {:tourney_done})
  end

  ### Server API

  def init(%Wordza.TourneyScheduleConfig{} = conf) do
    {:ok, conf |> Map.merge(%{tourney_scheduler_pid: self()})}
  end

  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:next}, _from, state) do
    {:ok, state} = Wordza.TourneyScheduler.next(state)
    {:reply, state, state}
  end
  def handle_call({:tourney_done}, _from, state) do
    {:ok, state} = Wordza.TourneyScheduler.tourney_done(state)
    {:reply, state, state}
  end
  # background process until complete
  def handle_call({:complete}, _from, state) do
    Process.send_after(self(), :loop_until_complete, @loop_delay)
    {:reply, state, state}
  end
  # loop until complete
  def handle_info(:loop_until_complete, state) do
    {:ok, state} = Wordza.TourneyScheduler.next(state)
    case state.number_left do
      0 ->
        Logger.info "TourneyScheduleWorker loop_until_complete is now done"
        # GenServer.stop(self())
        {:noreply, state}
      _ ->
        # Logger.info "TourneyScheduleWorker loop_until_complete ongoing #{inspect(state)}"
        Process.send_after(self(), :loop_until_complete, @loop_delay)
        {:noreply, state}
    end
  end


  # TO_DO should we implement swarm API?

end
