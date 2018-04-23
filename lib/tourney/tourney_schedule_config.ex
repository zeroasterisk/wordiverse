defmodule Wordza.TourneyScheduleConfig do
  @moduledoc """
  This is the config for a Schedule of Tourney Games
  It contains information needed to start each game
  and information about how many games we should run
  and how many games we can run in parallel
  """
  defstruct [
    # config for each Tourney Game
    type: nil,
    player_1_module: Wordza.BotAlec,
    player_2_module: Wordza.BotAlec,
    player_1_id: :p1,
    player_2_id: :p2,
    # config for Tourney Scheduler
    tourney_scheduler_pid: nil,
    id: nil,
    name: nil,
    number_of_games: 10,
    number_in_parallel: 2,
    # internal configurations
    done: false,
    number_running: 0,
    number_completed: 0,
    number_left: 0,
    running_tourney_pids: [],
    enable_loop: true,
  ]
  def create(type) do
    %Wordza.TourneyScheduleConfig{
      type: type,
    } |> calc()
  end
  def create(type, number_of_games, number_in_parallel \\ 2) do
    %Wordza.TourneyScheduleConfig{
      type: type,
      number_of_games: number_of_games,
      number_in_parallel: number_in_parallel,
    } |> calc()
  end
  def calc(
    %Wordza.TourneyScheduleConfig{
      number_of_games: total,
      number_completed: done,
      running_tourney_pids: running_tourney_pids,
    } = conf) do
      Map.merge(conf, %{
        number_running: Enum.count(running_tourney_pids),
        number_left: (total - done),
        done: (total - done == true),
      })
  end
end
