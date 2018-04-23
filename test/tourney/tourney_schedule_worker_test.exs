defmodule TourneyScheduleWorkerTest do

  use ExUnit.Case
  doctest Wordza.TourneyScheduleWorker

  @number_of_games 10
  @number_in_parallel 2

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      conf = Wordza.TourneyScheduleConfig.create(:mock, @number_of_games, @number_in_parallel)
      {:ok, conf: conf}
    end
    test "start should create game, but not play it", state do
      conf = state[:conf]
      {:ok, tsw_pid} = Wordza.TourneyScheduleWorker.start_link(conf)
      conf = Wordza.TourneyScheduleWorker.get(tsw_pid)
      conf_no_pid = Map.merge(conf, %{tourney_scheduler_pid: nil})
      assert conf_no_pid == %Wordza.TourneyScheduleConfig{
        type: :mock,
        player_1_id: :p1,
        player_2_id: :p2,
        player_1_module: Wordza.BotAlec,
        player_2_module: Wordza.BotAlec,
        id: nil,
        number_in_parallel: 2,
        number_of_games: 10,
        number_left: 10,
        number_completed: 0,
        number_running: 0,
        running_tourney_pids: [],
      }
    end
    test "expose next_step()", state do
      conf = state[:conf]
      assert conf.number_running == 0
      assert Enum.count(conf.running_tourney_pids) == 0
      {:ok, tsw_pid} = Wordza.TourneyScheduleWorker.start_link(conf)
      Wordza.TourneyScheduleWorker.pause(tsw_pid)
      conf = Wordza.TourneyScheduleWorker.next_step(tsw_pid)
      assert conf.number_in_parallel == 2
      assert conf.number_of_games == 10
      assert conf.number_left == 10
      assert conf.number_completed == 0
      assert conf.number_running == 2
      assert Enum.count(conf.running_tourney_pids) == 2
    end
    test "expose next_step() x3 with pauses, to let games finish", state do
      conf = state[:conf]
      {:ok, tsw_pid} = Wordza.TourneyScheduleWorker.start_link(conf)
      Wordza.TourneyScheduleWorker.pause(tsw_pid)
      Wordza.TourneyScheduleWorker.next_step(tsw_pid)
      conf = Wordza.TourneyScheduleWorker.next_step(tsw_pid)
      # started 2 games, they are in progress (not complete)
      assert conf.number_in_parallel == 2
      assert conf.number_of_games == 10
      assert conf.number_left == 10
      assert conf.number_completed == 0
      assert conf.number_running == 2
      assert Enum.count(conf.running_tourney_pids) == 2
      # allow those started games to complete
      # TO_DO force the completion and de-registration of the games
      Process.sleep(200)
      conf = Wordza.TourneyScheduleWorker.get(tsw_pid)
      # those games are done
      assert conf.number_in_parallel == 2
      assert conf.number_of_games == 10
      assert conf.number_left == 8
      assert conf.number_completed == 2
      assert conf.number_running == 0
      assert Enum.empty?(conf.running_tourney_pids) == true
      # next_step should start 2 more
      conf = Wordza.TourneyScheduleWorker.next_step(tsw_pid)
      # started 2 games, they are in progress (not complete)
      assert conf.number_in_parallel == 2
      assert conf.number_of_games == 10
      assert conf.number_left == 8
      assert conf.number_completed == 2
      assert conf.number_running == 2
      assert Enum.count(conf.running_tourney_pids) == 2
      # allow those started games to complete
      # TO_DO force the completion and de-registration of the games
      Process.sleep(200)
      conf = Wordza.TourneyScheduleWorker.get(tsw_pid)
      # those games are done
      assert conf.number_in_parallel == 2
      assert conf.number_of_games == 10
      assert conf.number_left == 6
      assert conf.number_completed == 4
      assert conf.number_running == 0
      assert Enum.empty?(conf.running_tourney_pids) == true
      # and so on and so forth
    end
    # test "expose complete()", state do
    #   conf = state[:conf]
    #   {:ok, tsw_pid} = Wordza.TourneyScheduleWorker.start_link(conf)
    #   conf = Wordza.TourneyScheduleWorker.complete(tsw_pid)
    #   Process.sleep(200)
    #   assert conf.number_in_parallel == 2
    #   assert conf.number_of_games == 10
    #   assert conf.number_left == 10
    #   assert conf.number_completed == 0
    #   assert conf.number_running == 2
    #   assert Enum.count(conf.running_tourney_pids) == 2
    # end

    ######################
    ## Internal Private ##
    ######################

    test "get the next_get_spawn_count() @number_in_parallel if nothing started", state do
      assert Wordza.TourneyScheduleWorker.next_get_spawn_count(state[:conf]) == @number_in_parallel
    end
    test "get the next_get_spawn_count() 1 if number_running=1", state do
      conf = state[:conf] |> Map.merge(%{number_running: 1})
      assert Wordza.TourneyScheduleWorker.next_get_spawn_count(conf) == 1
    end
    test "get the next_get_spawn_count() 0 if number_running=@number_in_parallel", state do
      conf = state[:conf] |> Map.merge(%{number_running: 2})
      assert Wordza.TourneyScheduleWorker.next_get_spawn_count(conf) == 0
    end
    test "demo next_spawn_games() do nothing, if 0 games to start", state do
      assert Wordza.TourneyScheduleWorker.next_spawn_games(state[:conf], 0) == state[:conf]
    end
    test "demo next_spawn_games() spawn 2 games", state do
      conf = Wordza.TourneyScheduleWorker.next_spawn_games(state[:conf], 2)
      assert conf.number_running == 2
    end
    test "demo next_spawn_games() spawn 3 games", state do
      conf = Wordza.TourneyScheduleWorker.next_spawn_games(state[:conf], 3)
      assert conf.number_running == 3
    end
    test "use next_spawn_game() to start a single game", state do
      conf = Wordza.TourneyScheduleWorker.next_spawn_game(state[:conf])
      assert conf.number_running == 1
      assert conf.running_tourney_pids |> Enum.count() == 1
      tourney_pid = conf.running_tourney_pids |> List.first()
      assert tourney_pid |> is_pid() == true
      assert Process.alive?(tourney_pid) == true
      tourney_conf = Wordza.TourneyGameWorker.get(tourney_pid)
      game_pid = tourney_conf.game_pid
      assert game_pid |> is_pid() == true
      assert Process.alive?(game_pid) == true
      # TO_DO force the completion and de-registration of the games
      Process.sleep(200)
      assert Process.alive?(game_pid) == false
      # game_conf = Wordza.Game.get(game_pid) <-- can't get this status after the fact
      # assert Enum.count(game_conf.plays) > 0 TODO check this out
    end


  end
end
