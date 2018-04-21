defmodule TourneyScheduleWorkerTest do

  use ExUnit.Case
  doctest Wordza.TourneyScheduleWorker

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      conf = Wordza.TourneyScheduleConfig.create(:mock, 10, 2)
      {:ok, conf: conf}
    end
    test "start should create game, but not play it", state do
      conf = state[:conf]
      {:ok, tw_pid} = Wordza.TourneyScheduleWorker.start_link(conf)
      conf = Wordza.TourneyScheduleWorker.get(tw_pid)
      assert conf == %Wordza.TourneyScheduleConfig{
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
        running_game_ids: [],
      }
    end
    test "expose next()", state do
      conf = state[:conf]
      {:ok, tw_pid} = Wordza.TourneyScheduleWorker.start_link(conf)
      conf = Wordza.TourneyScheduleWorker.next(tw_pid)
      assert conf.number_in_parallel == 2
      assert conf.number_of_games == 10
      assert conf.number_left == 10
      assert conf.number_completed == 0
      assert conf.number_running == 2
      assert Enum.count(conf.running_game_ids) == 2
    end
  end
end
