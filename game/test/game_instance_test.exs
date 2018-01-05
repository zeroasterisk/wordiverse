defmodule GameInstanceTest do
  use ExUnit.Case
  doctest Wordza.GameInstance

  test "creates the game" do
    type = :wordfeud
    player_1_id = :bot_lookahead_1
    player_2_id = :bot_lookahead_2
    game = Wordza.GameInstance.create(type, player_1_id, player_2_id)
    assert game.type == type
    assert game.player_1.id == player_1_id
    assert game.player_2.id == player_2_id
    # enusre each player has taken 7 tiles
    assert Enum.count(game.player_1.tiles_in_tray) == 7
    assert Enum.count(game.player_2.tiles_in_tray) == 7
    assert Enum.count(game.tiles_in_pile) == 90
  end

  test "fill a player's tray with tiles" do
    tiles = Wordza.GameTiles.create(:wordfeud)
    p1 = Wordza.GamePlayer.create(:p1)
    game = %Wordza.GameInstance{type: :wordfeud, tiles_in_pile: tiles, player_1: p1}
    game = Wordza.GameInstance.fill_player_tiles(game, :player_1)
    # enusre each player has taken 7 tiles
    assert Enum.count(game.player_1.tiles_in_tray) == 7
    assert Enum.count(game.tiles_in_pile) == 97
    # ensure fill_player_tiles does not take extra tiles, if not needed
    game = Wordza.GameInstance.fill_player_tiles(game, :player_1)
    # if the player has played 5 tiles, it should re-fill their tray
    p1 = game |> Map.get(:player_1)
    tiles_in_tray = p1 |> Map.get(:tiles_in_tray) |> Enum.slice(0, 2)
    p1 = p1 |> Map.merge(%{tiles_in_tray: tiles_in_tray})
    game = game |> Map.merge(%{player_1: p1})
    assert Enum.count(game.player_1.tiles_in_tray) == 2
    assert Enum.count(game.tiles_in_pile) == 97
    game = Wordza.GameInstance.fill_player_tiles(game, :player_1)
    assert Enum.count(game.player_1.tiles_in_tray) == 7
    assert Enum.count(game.tiles_in_pile) == 92
  end

end
