defmodule BotAlecTest do
  use ExUnit.Case
  doctest Wordza.BotAlec
  alias Wordza.BotAlec
  alias Wordza.GameBoard

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      game = Wordza.GameInstance.create(:mock, :player_1, :player_2)
      player_1 = game
                 |> Map.get(:player_1)
                 |> Map.merge(%{tiles_in_tray: Wordza.GameTiles.create(:mock_tray)})
      game = game |> Map.merge(%{player_1: player_1})
      {:ok, game: game}
    end

    test "play should pick best next play", state do
      played = [
        %{letter: "A", y: 2, x: 0, value: 1},
        %{letter: "L", y: 2, x: 1, value: 1},
        %{letter: "L", y: 2, x: 2, value: 1},
      ]
      board = state[:game] |> Map.get(:board) |> GameBoard.add_letters(played)
      game = state[:game] |> Map.merge(%{board: board})
      {:ok, play} = BotAlec.make_play(:player_1, game)
      assert play.score == 16 # (got a :dw twice!)
      assert play.board_next |> GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, "A", nil, nil, nil],
        ["A", "L", "L", nil, nil],
        [nil, "A", nil, nil, nil],
        [nil, "N", nil, nil, nil],
      ]
      assert play.tiles_in_play == [
        %Wordza.GameTile{letter: "A", value: 1, y: 1, x: 1},
        %Wordza.GameTile{value: 1, letter: "A", x: 1, y: 3},
        %Wordza.GameTile{value: 1, letter: "N", x: 1, y: 4}
      ]
      assert play.tiles_in_tray == [
        %Wordza.GameTile{letter: "L", value: 1, x: nil, y: nil},
        %Wordza.GameTile{letter: "L", value: 1, x: nil, y: nil},
      ]
    end
    test "play should pick best first play", state do
      game = state[:game]
      {:ok, play} = BotAlec.make_play(:player_1, game)
      assert play.score == 12 # (got a :st + :tl!)
      assert play.board_next |> GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, nil, "A", nil, nil],
        [nil, nil, "L", nil, nil],
        [nil, nil, "A", nil, nil],
        [nil, nil, "N", nil, nil],
      ]
      assert play.tiles_in_play == [
        %Wordza.GameTile{letter: "A", value: 1, x: 2, y: 1},
        %Wordza.GameTile{letter: "L", value: 1, x: 2, y: 2},
        %Wordza.GameTile{letter: "A", value: 1, x: 2, y: 3},
        %Wordza.GameTile{letter: "N", value: 1, x: 2, y: 4},
      ]
      assert play.tiles_in_tray == [
        %Wordza.GameTile{letter: "L", value: 1, x: nil, y: nil},
      ]
    end
  end
end

