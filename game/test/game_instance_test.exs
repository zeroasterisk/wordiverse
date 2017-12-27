defmodule GameInstanceTest do
  use ExUnit.Case
  doctest Wordiverse.Game

  test "creates the game" do
    type = :wordfeud
    player_1_id = :bot_lookahead_1
    player_2_id = :bot_lookahead_2
    game = Wordiverse.GameInstance.create(type, player_1_id, player_2_id)
    assert game.type == type
    assert game.player_1.id == player_1_id
    assert game.player_2.id == player_2_id
    # enusre each player has taken 7 tiles
    assert Enum.count(game.player_1.tiles_in_tray) == 7
    assert Enum.count(game.player_2.tiles_in_tray) == 7
    assert Enum.count(game.tiles_in_pile) == 90
  end
end
