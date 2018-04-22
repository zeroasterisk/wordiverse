defmodule TourneySchedulerTest do

  use ExUnit.Case
  doctest Wordza.TourneyScheduler

  @number_of_games 10
  @number_in_parallel 2

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      conf = Wordza.TourneyScheduleConfig.create(:mock, @number_of_games, @number_in_parallel)
      {:ok, conf: conf}
    end
    test "get the next_get_spawn_count() @number_in_parallel if nothing started", state do
      assert Wordza.TourneyScheduler.next_get_spawn_count(state[:conf]) == @number_in_parallel
    end
    test "get the next_get_spawn_count() 1 if number_running=1", state do
      conf = state[:conf] |> Map.merge(%{number_running: 1})
      assert Wordza.TourneyScheduler.next_get_spawn_count(conf) == 1
    end
    test "get the next_get_spawn_count() 0 if number_running=@number_in_parallel", state do
      conf = state[:conf] |> Map.merge(%{number_running: 2})
      assert Wordza.TourneyScheduler.next_get_spawn_count(conf) == 0
    end
    test "demo next_spawn_games() do nothing, if 0 games to start", state do
      assert Wordza.TourneyScheduler.next_spawn_games(state[:conf], 0) == state[:conf]
    end
    test "demo next_spawn_games() spawn 2 games", state do
      conf = Wordza.TourneyScheduler.next_spawn_games(state[:conf], 2)
      assert conf.number_running == 2
    end
    test "demo next_spawn_games() spawn 3 games", state do
      conf = Wordza.TourneyScheduler.next_spawn_games(state[:conf], 3)
      assert conf.number_running == 3
    end
    test "use next_spawn_game() to start a single game", state do
      conf = Wordza.TourneyScheduler.next_spawn_game(state[:conf])
      assert conf.number_running == 1
      assert conf.running_game_ids |> Enum.count() == 1
      game_pid = conf.running_game_ids |> List.first()
      assert game_pid |> is_pid() == true
      IO.inspect conf
    end
  end
end
