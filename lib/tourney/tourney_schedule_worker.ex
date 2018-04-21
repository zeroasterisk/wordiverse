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


  ### Server API

  def init(%Wordza.TourneyScheduleConfig{} = conf) do
    {:ok, conf}
  end

  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:next}, _from, state) do
    {:ok, state} = Wordza.TourneyScheduler.next(state)
    {:reply, state, state}
  end
  def handle_call({:complete}, _from, state) do
    {:ok, state} = Wordza.TourneyScheduler.complete(state)
    {:reply, state, state}
  end

  # TO_DO should we implement swarm API?

end
