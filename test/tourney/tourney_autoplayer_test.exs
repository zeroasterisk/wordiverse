defmodule TourneyAutoplayerTest do

  use ExUnit.Case
  doctest Wordza.TourneyAutoplayer

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      conf = Wordza.TourneyConfig.create(:mock)
      {:ok, game_pid} = Wordza.Game.start_link(conf.type, conf.player_1_id, conf.player_2_id)
      conf = Map.merge(conf, %{game_pid: game_pid})
      {:ok, conf: conf, game_pid: game_pid}
    end
    test "next() play for a full run of a complete game", state do
      conf = state[:conf]
      game_pid = state[:game_pid]
      # sanity check
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == 1
      assert game.board |> Wordza.GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
      ]
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == 2
      assert game.board |> Wordza.GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, "A", nil, nil],
        [nil, nil, "L", nil, nil],
        [nil, nil, "A", nil, nil],
        [nil, nil, "N", nil, nil],
      ]
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      game = Wordza.Game.get(game_pid, :full)
      assert game.board |> Wordza.GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, "A", nil, nil],
        [nil, nil, "L", nil, nil],
        ["A", "L", "A", "N", nil],
        [nil, nil, "N", nil, nil],
      ]
      # after this, we don't know what's in the player hands anymore
      # because of a bit of random distrobution
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == 2
      assert game.plays |> Enum.count() == 3
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == 1
      assert game.plays |> Enum.count() == 4
      # TO_DO could do a better job and make the game know it's over here
      # we should have run out of plays here (depending on distrobution)
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      {:ok, conf} = Wordza.TourneyAutoplayer.next(conf)
      assert conf.done == true
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == :game_over
      # assert that the last thing in the list of plays is a pass
      #   we can not be sure of who passed, because letter distrobution
      pass_nice = game.plays |> List.first() |> Map.merge(%{
        timestamp: nil,
        player_key: :player_1,
      })
      assert pass_nice == %Wordza.GamePass{player_key: :player_1}
    end
    test "complete() should complete a full run of a complete game in 1 go (blocking)", state do
      conf = state[:conf]
      game_pid = state[:game_pid]
      # sanity check
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == 1
      assert game.board |> Wordza.GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
      ]
      {:ok, conf} = Wordza.TourneyAutoplayer.complete(conf)
      assert conf.done == true
      game = Wordza.Game.get(game_pid, :full)
      assert game.turn == :game_over
      # assert that the last thing in the list of plays is a pass
      #   we can not be sure of who passed, because letter distrobution
      pass_nice = game.plays |> List.first() |> Map.merge(%{
        timestamp: nil,
        player_key: :player_1,
      })
      assert pass_nice == %Wordza.GamePass{player_key: :player_1}
      assert game.plays |> Enum.count() > 4
      assert game.tiles_in_pile == []
      assert game.player_1.score > 14
      assert game.player_2.score > 14
      # IO.inspect game
      # IO.puts game.board |> Wordza.GameBoard.to_string()
    end
  end
end
