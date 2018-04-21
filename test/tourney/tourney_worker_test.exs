defmodule TourneyWorkerTest do

  use ExUnit.Case
  doctest Wordza.TourneyWorker

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      conf = Wordza.TourneyConfig.create(:mock)
      {:ok, conf: conf}
    end
    test "start should create game, but not play it", state do
      conf = state[:conf]
      assert conf.game_pid == nil
      {:ok, tw_pid} = Wordza.TourneyWorker.start_link(conf)
      conf = Wordza.TourneyWorker.get(tw_pid)
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
      {:ok, tw_pid} = Wordza.TourneyWorker.start_link(conf)
      conf = Wordza.TourneyWorker.next(tw_pid)
      assert is_pid(conf.game_pid) == true
      game_pid = conf.game_pid
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == 2
      assert game.plays |> Enum.count() == 1
    end
    test "expose complete()", state do
      conf = state[:conf]
      assert conf.game_pid == nil
      {:ok, tw_pid} = Wordza.TourneyWorker.start_link(conf)
      conf = Wordza.TourneyWorker.complete(tw_pid)
      assert is_pid(conf.game_pid) == true
      game_pid = conf.game_pid
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == :game_over
      # even though we are complete, we are not killing the Game Server
      assert Process.alive?(game_pid) == true
      # even though we are complete, we are not killing the TourneyWorker Server
      assert Process.alive?(tw_pid) == true
    end
    test "do a single-run play_game()", state do
      conf = state[:conf]
      assert conf.game_pid == nil
      {:ok, conf} = Wordza.TourneyWorker.play_game(conf)
      assert is_pid(conf.game_pid) == true
      assert Process.alive?(conf.game_pid) == false
    end
  end
end
