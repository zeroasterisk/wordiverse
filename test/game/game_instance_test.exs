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

  describe "game and game_play" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      game = Wordza.GameInstance.create(:mock, :player_1, :player_2)
      tray = []
            |> Wordza.GameTiles.add("A", 1, 2)
            |> Wordza.GameTiles.add("L", 1, 2)
            |> Wordza.GameTiles.add("N", 1, 2)
            |> Wordza.GameTiles.add("D", 1, 1)
      player = Map.merge(game.player_1, %{tiles_in_tray: tray})
      game = game |> Map.merge(%{
        player_1: player,
        tiles_in_pile: [] |> Wordza.GameTiles.add("X", 1, 10),
      })
      # create a killer play
      letters_yx = [
        ["A", 0, 2],
        ["L", 1, 2],
        ["L", 2, 2],
      ]
      play = :player_1
             |> Wordza.GamePlay.create(letters_yx)
             |> Wordza.GamePlay.verify(game)
      {:ok, play: play, game: game, player: player}
    end

    test "apply a player's play to a game", state do
      # sanity
      assert state[:play] |> Map.get(:score) == 10
      assert state[:game] |> Map.get(:plays) == []
      player_1 = Map.get(state[:game], :player_1)
      assert player_1 |> Map.get(:score) == 0
      assert player_1 |> Map.get(:tiles_in_tray) |> Enum.sort() == [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "D", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
      ]
      assert player_1 |> Map.get(:score) == 0
      # apply a play to a game
      {:ok, game} = Wordza.GameInstance.apply_play(state[:game], state[:play])
      # verify the player
      player_1 = Map.get(game, :player_1)
      assert player_1 |> Map.get(:score) == 10
      assert player_1 |> Map.get(:tiles_in_tray) |> Enum.sort() == [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "D", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
      ]
      # verify the game board
      assert game |> Map.get(:board) == state[:play] |> Map.get(:board_next)
      # verify the game tiles (10 - 7)
      assert game |> Map.get(:tiles_in_pile) == [
        %Wordza.GameTile{letter: "X", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
      ]
      # verify the game play log (omit timestamp)
      assert game |> Map.get(:plays) |> Enum.count() == 1
      play_nice = game
                  |> Map.get(:plays)
                  |> List.first()
                  |> Map.merge(%{timestamp: nil})
      assert play_nice == state[:play]
    end
  end

end
