defmodule AutoplayedTest do

  use ExUnit.Case
  doctest Wordza.Autoplayer

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      {:ok, game_pid} = Wordza.Game.start_link(:mock, :bot_lookahead_1, :bot_lookahead_2)
      game = Wordza.Game.get(game_pid, :full)
      {:ok, game: game, game_pid: game_pid}
    end
    test "init creates the autoplayer as a GenServer - mock run", state do
      {:ok, auto_player_pid} = Wordza.Autoplayer.start_link(state[:game_pid], Wordza.BotAlec, Wordza.BotAlec)
      # sanity check
      game = Wordza.Game.get(state[:game_pid], :full)
      assert game.turn == 1
      assert game.board |> Wordza.GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
      ]
      {:ok, game} = Wordza.Autoplayer.play_next(auto_player_pid)
      assert game.turn == 2
      assert game.board |> Wordza.GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, "A", nil, nil],
        [nil, nil, "L", nil, nil],
        [nil, nil, "A", nil, nil],
        [nil, nil, "N", nil, nil],
      ]
      {:ok, game} = Wordza.Autoplayer.play_next(auto_player_pid)
      assert game.board |> Wordza.GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, "A", nil, nil],
        [nil, nil, "L", nil, nil],
        ["A", "L", "A", "N", nil],
        [nil, nil, "N", nil, nil],
      ]
      # after this, we don't know what's in the player hands anymore
      # because of a bit of random distrobution
      {:ok, game} = Wordza.Autoplayer.play_next(auto_player_pid)
      assert game.turn == 2
      assert game.plays |> Enum.count() == 3
      {:ok, game} = Wordza.Autoplayer.play_next(auto_player_pid)
      assert game.turn == 1
      assert game.plays |> Enum.count() == 4
      # TO_DO could do a better job and make the game know it's over here
      # we should have run out of plays here (depending on distrobution)
      {:ok, _game} = Wordza.Autoplayer.play_next(auto_player_pid)
      {:ok, _game} = Wordza.Autoplayer.play_next(auto_player_pid)
      {_, _game} = Wordza.Autoplayer.play_next(auto_player_pid)
      {_, _game} = Wordza.Autoplayer.play_next(auto_player_pid)
      {_, _game} = Wordza.Autoplayer.play_next(auto_player_pid)
      {:done, game} = Wordza.Autoplayer.play_next(auto_player_pid)
      assert game.turn == :game_over
      # assert that the last thing in the list of plays is a pass
      #   we can not be sure of who passed, because letter distrobution
      pass_nice = game.plays |> List.first() |> Map.merge(%{
        timestamp: nil,
        player_key: :player_1,
      })
      assert pass_nice == %Wordza.GamePass{player_key: :player_1}
    end
    test "running an autoplayer should complete a game, with a bot on both sides", state do
      {:ok, auto_player_pid} = Wordza.Autoplayer.start_link(state[:game_pid], Wordza.BotAlec, Wordza.BotAlec)
      # sanity check
      game = Wordza.Game.get(state[:game_pid], :full)
      assert game.turn == 1
      assert game.board |> Wordza.GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil],
      ]
      {:done, game} = Wordza.Autoplayer.play_game(auto_player_pid)
      assert game.turn == :game_over
      assert game.plays |> Enum.count() > 4
      assert game.tiles_in_pile == []
      assert game.player_1.score > 14
      assert game.player_2.score > 14
      # IO.inspect game
      # IO.puts game.board |> Wordza.GameBoard.to_string()
    end
    test "autoplayer should be able to complete 10 games in series", _state do
      Range.new(0, 10) |> Enum.each(fn(_) ->
        {:ok, game_pid} = Wordza.Game.start_link(:mock, :bot_lookahead_1, :bot_lookahead_2)
        {:ok, auto_player_pid} = Wordza.Autoplayer.start_link(game_pid, Wordza.BotAlec, Wordza.BotAlec)
        {:done, game} = Wordza.Autoplayer.play_game(auto_player_pid)
        assert game.turn == :game_over
        assert game.plays |> Enum.count() > 4
        assert game.tiles_in_pile == []
        assert game.player_1.score > 14
        assert game.player_2.score > 14
        # IO.inspect game
        # IO.puts game.board |> Wordza.GameBoard.to_string()
      end)
    end
    test "autoplayer should be able to complete 10 games in parallel", _state do
      _game_pids = Range.new(0, 10) |> Enum.map(fn(_) ->
        {:ok, game_pid} = Wordza.Game.start_link(:mock, :bot_lookahead_1, :bot_lookahead_2)
        {:ok, auto_player_pid} = Wordza.Autoplayer.start_link(game_pid, Wordza.BotAlec, Wordza.BotAlec)
        :ok = Wordza.Autoplayer.play_game_background(auto_player_pid)
        game_pid
      end)
      # TODO wait until done
      #  then check all game_pids
      # TODO should have a better test for parallel execution
    end
  end
end
