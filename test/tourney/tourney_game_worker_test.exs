defmodule TourneyGameWorkerTest do

  use ExUnit.Case
  doctest Wordza.TourneyGameWorker

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      conf = Wordza.TourneyGameConfig.create(:mock)
      {:ok, conf: conf}
    end
    test "start should create game, but not play it", state do
      conf = state[:conf]
      assert conf.game_pid == nil
      {:ok, tw_pid} = Wordza.TourneyGameWorker.start_link(conf)
      conf = Wordza.TourneyGameWorker.get(tw_pid)
      assert is_pid(conf.game_pid) == true
      game_pid = conf.game_pid
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == 1
      assert game.board |> Wordza.GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
      ]
      assert game.plays |> Enum.empty?() == true
    end
    test "expose next()", state do
      conf = state[:conf]
      assert conf.game_pid == nil
      {:ok, tw_pid} = Wordza.TourneyGameWorker.start_link(conf)
      conf = Wordza.TourneyGameWorker.next(tw_pid)
      assert is_pid(conf.game_pid) == true
      game_pid = conf.game_pid
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == 2
      assert game.plays |> Enum.count() == 1
    end
    test "expose complete_game()", state do
      conf = state[:conf]
      assert conf.game_pid == nil
      {:ok, tw_pid} = Wordza.TourneyGameWorker.start_link(conf)
      conf = Wordza.TourneyGameWorker.complete_game(tw_pid)
      assert is_pid(conf.game_pid) == true
      game_pid = conf.game_pid
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == :game_over
      # even though we are complete, we are not killing the Game Server
      assert Process.alive?(game_pid) == true
      # even though we are complete, we are not killing the TourneyGameWorker Server
      assert Process.alive?(tw_pid) == true
      # that killing is done in shutdown()
    end
    test "expose shutdown() ensure closes servers", state do
      conf = state[:conf]
      assert conf.game_pid == nil
      {:ok, tw_pid} = Wordza.TourneyGameWorker.start_link(conf)
      conf = Wordza.TourneyGameWorker.complete_game(tw_pid)
      Wordza.TourneyGameWorker.shutdown(tw_pid)
      Wordza.TourneyGameWorker.stop(tw_pid)
      Process.sleep(100)
      assert Process.alive?(conf.game_pid) == false
      assert Process.alive?(tw_pid) == false
    end
    test "do a single-run play_game() (sync)", state do
      conf = state[:conf]
      assert conf.game_pid == nil
      # tourney_scheduler_pid not setup in testing
      assert is_nil(conf.tourney_scheduler_pid) == true
      {:ok, conf} = Wordza.TourneyGameWorker.play_game(conf)
      assert is_pid(conf.game_pid) == true
      assert is_pid(conf.tourney_worker_pid) == true
      # tourney_scheduler_pid not setup in testing
      assert is_nil(conf.tourney_scheduler_pid) == true
      # Game and Tourney should be shut down now, we are done
      assert Process.alive?(conf.game_pid) == false
      assert Process.alive?(conf.tourney_worker_pid) == false
    end
    # test "expose complete_game_bg()", state do
    #   conf = state[:conf]
    #   assert conf.game_pid == nil
    #   {:ok, tw_pid} = Wordza.TourneyGameWorker.start_link(conf)
    #   :ok = Wordza.TourneyGameWorker.complete_game_bg(tw_pid)
    #   conf = Wordza.TourneyGameWorker.get(tw_pid)
    #   assert is_pid(conf.game_pid) == true
    #   game_pid = conf.game_pid
    #   game = Wordza.Game.get(game_pid, :full)
    #   assert game.turn == 1
    #   assert game.plays |> Enum.count() == 0
    #   Process.sleep 500
    #   conf = Wordza.TourneyGameWorker.get(tw_pid)
    #   assert is_pid(conf.game_pid) == true
    #   game_pid = conf.game_pid
    #   game = Wordza.Game.get(game_pid, :full)
    #   # assert game.turn == 1
    #   assert game.plays |> Enum.count() == 1
    #   # even though we are complete, we are not killing the Game Server
    #   assert Process.alive?(game_pid) == true
    #   # even though we are complete, we are not killing the TourneyGameWorker Server
    #   assert Process.alive?(tw_pid) == true
    #   # that killing is done in shutdown()
    # end
  end
end
