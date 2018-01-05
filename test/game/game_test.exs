defmodule GameTest do
  use ExUnit.Case
  doctest Wordza.Game

  test "init creates the game as a GenServer" do
    type = :wordfeud
    player_1_id = :bot_lookahead_1
    player_2_id = :bot_lookahead_2
    {:ok, game_pid} = Wordza.Game.start_link(type, player_1_id, player_2_id)
    game = Wordza.Game.get(game_pid, :full)
    assert game.type == type
    assert game.player_1.id == player_1_id
    assert game.player_2.id == player_2_id
    # enusre each player has taken 7 tiles
    assert Enum.count(game.player_1.tiles_in_tray) == 7
    assert Enum.count(game.player_2.tiles_in_tray) == 7
    assert Enum.count(game.tiles_in_pile) == 90
  end

  test "get gets the game various states :full is special and gets all things" do
    type = :wordfeud
    player_1_id = :bot_lookahead_1
    player_2_id = :bot_lookahead_2
    {:ok, game_pid} = Wordza.Game.start_link(type, player_1_id, player_2_id)
    game = Wordza.Game.get(game_pid, :full)
    assert Wordza.Game.get(game_pid, :board) == game.board
    assert Wordza.Game.get(game_pid, :player_1) == game.player_1
    assert Wordza.Game.get(game_pid, :player_2) == game.player_2
    assert Wordza.Game.get(game_pid, :tiles) == game.tiles_in_pile
  end

end
