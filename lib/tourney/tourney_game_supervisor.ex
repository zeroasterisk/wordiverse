defmodule Wordza.TourneyGameSupervisor do
  @moduledoc """
  This is the supervisor for the tourney processes
  """
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Wordza.TourneyGameWorker, [], restart: :temporary)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  @doc """
  Registers a new worker, and creates the worker process
  """
  def register(worker_name) do
    {:ok, _pid} = Supervisor.start_child(__MODULE__, [worker_name])
  end
end
