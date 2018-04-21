defmodule Wordza.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Wordza.Game.Worker.start_link(arg)
      # %{id: DictionaryMock, start: {Wordza.Dictionary, :start_link, [:mock]}},
      # %{id: DictionaryScrabble, start: {Wordza.Dictionary, :start_link, [:scrabble]}},
      # %{id: TourneySchedulerBasic, start: {Wordza.TourneyScheduleWorker, :start_link, [:basic_test_small]}},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wordza.MasterSupervisor]
    Supervisor.start_link(children, opts)
  end
end
