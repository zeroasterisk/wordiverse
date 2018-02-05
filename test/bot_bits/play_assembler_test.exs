defmodule PlayAssemblerTest do
  use ExUnit.Case
  # doctest Wordza.PlayAssembler
  alias Wordza.PlayAssembler
  alias Wordza.GameBoard
  alias Wordza.BotBits

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      game = Wordza.GameInstance.create(:mock, :player_1, :player_2)
      played = [
        %{letter: "A", y: 2, x: 0, value: 1},
        %{letter: "L", y: 2, x: 1, value: 1},
        %{letter: "L", y: 2, x: 2, value: 1},
      ] # <-- played already "ALL" horiz
      game = game |> Map.merge(%{
        board: game
        |> Map.get(:board)
        |> GameBoard.add_letters(played),
        player_1: game
        |> Map.get(:player_1)
        |> Map.merge(%{tiles_in_tray: Wordza.GameTiles.create(:mock_tray)}),
      })
      {:ok, game: game}
    end

    test "create should create nil for unplayable word 'A' (wrong length)", state do
      start_yx = [0, 2]
      word_start = ["A"]
      play = %Wordza.GamePlay{} = PlayAssembler.create(state[:game], %{
        direction: :y,
        player_key: :player_1,
        start_yx: start_yx,
        word_start: word_start,
      })
      assert play.valid == false
      assert play.errors == ["Tiles must touch an existing tile"]
    end
    test "create should create nil for unplayable word 'ALL' (wrong length)", state do
      start_yx = [0, 2]
      word_start = ["A", "L", "L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create(state[:game], %{
        direction: :y,
        player_key: :player_1,
        start_yx: start_yx,
        word_start: word_start,
      })
      assert play.valid == false
      assert play.errors == ["Tiles may not overlap"]
    end
    test "create should create nil for unplayable word 'BS' (not in tray)", state do
      start_yx = [0, 2]
      word_start = ["B", "S"]
      play = %Wordza.GamePlay{} = PlayAssembler.create(state[:game], %{
        direction: :y,
        player_key: :player_1,
        start_yx: start_yx,
        word_start: word_start,
      })
      assert play.valid == false
      assert play.errors == ["Tiles not in your tray"]
    end
    test "create should create nil for unplayable word 'ALL' (no played letter, in y direction)", state do
      start_yx = [0, 3]
      word_start = ["A", "L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create(state[:game], %{
        direction: :y,
        player_key: :player_1,
        start_yx: start_yx,
        word_start: word_start,
      })
      assert play.valid == false
      assert play.errors == ["Tiles must touch an existing tile"]
    end
    test "create should create a play for playable word 'AL'", state do
      start_yx = [0, 2]
      word_start = ["A", "L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create(state[:game], %{
        direction: :y,
        player_key: :player_1,
        start_yx: start_yx,
        word_start: word_start,
      })
      assert play.direction == :y
      assert play.valid == true
      assert play.errors == []
      assert play.letters_yx == [["A", 0, 2], ["L", 1, 2]]
      assert play.tiles_in_play == [
        %Wordza.GameTile{letter: "A", value: 1, x: 2, y: 0},
        %Wordza.GameTile{letter: "L", value: 1, x: 2, y: 1},
      ]
      assert play.tiles_in_tray == [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
      ]
      assert play.words == [
        [
          %{bonus: :tl, letter: "A", value: 1, x: 2, y: 0},
          %{bonus: nil, letter: "L", value: 1, x: 2, y: 1},
          %{bonus: :st, letter: "L", value: 1, x: 2, y: 2},
        ]
      ]
      assert play.score == 5 # ((1*3) + 1 + 1) [no :st double word, already played]
    end
    test "create should create a play for a word 'L' after the already played 'A'", state do
      start_yx = [3, 0]
      word_start = ["L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create(state[:game], %{
        direction: :y,
        player_key: :player_1,
        start_yx: start_yx,
        word_start: word_start,
      })
      assert play.direction == :y
      assert play.valid == true
      assert play.errors == []
      assert play.tiles_in_play == [
        %Wordza.GameTile{letter: "L", value: 1, x: 0, y: 3},
      ]
      assert play.tiles_in_tray == [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
      ]
      assert play.words == [
        [
          %{bonus: :dl, letter: "A", value: 1, x: 0, y: 2},
          %{bonus: nil, letter: "L", value: 1, x: 0, y: 3},
        ]
      ]
      assert play.score == 2 # (1 + 1) [no :dl double letter, already played]
    end

    test "create_all_plays should create whole lot of plays", state do
      board = state[:game] |> Map.get(:board)
      type = state[:game] |> Map.get(:type)
      tiles_in_tray = state[:game] |> Map.get(:player_1) |> Map.get(:tiles_in_tray)
      start_yxs = BotBits.get_all_start_yx(board, tiles_in_tray)
      word_starts = BotBits.get_all_word_starts(tiles_in_tray, type)
      plays = PlayAssembler.create_all_plays(state[:game], %{
        player_key: :player_1,
        start_yxs: start_yxs,
        word_starts: word_starts,
      })
      assert Enum.count(plays) == 15
      first = Enum.at(plays, 0)
      assert first.score == 16
      assert first.board_next |> GameBoard.to_list == [
        [nil, nil, nil, nil, nil],
        [nil, "A", nil, nil, nil],
        ["A", "L", "L", nil, nil],
        [nil, "A", nil, nil, nil],
        [nil, "N", nil, nil, nil]
      ]
      assert first.tiles_in_play == [
        %Wordza.GameTile{letter: "A", value: 1, x: 1, y: 1},
        %Wordza.GameTile{letter: "A", value: 1, x: 1, y: 3},
        %Wordza.GameTile{letter: "N", value: 1, x: 1, y: 4}
      ]
      assert first.tiles_in_tray == [
        %Wordza.GameTile{letter: "L", value: 1, x: nil, y: nil},
        %Wordza.GameTile{letter: "L", value: 1, x: nil, y: nil},
      ]
      alt_play = Enum.at(plays, 10)
      assert alt_play.score == 5
      assert alt_play.board_next |> GameBoard.to_list == [
        [nil, nil, "A", nil, nil],
        [nil, nil, "L", nil, nil],
        ["A", "L", "L", nil, nil],
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil]
      ]
      assert alt_play.tiles_in_play == [
        %Wordza.GameTile{letter: "A", value: 1, x: 2, y: 0},
        %Wordza.GameTile{letter: "L", value: 1, x: 2, y: 1}
      ]
      assert alt_play.tiles_in_tray == [
        %Wordza.GameTile{letter: "A", value: 1, x: nil, y: nil},
        %Wordza.GameTile{letter: "L", value: 1, x: nil, y: nil},
        %Wordza.GameTile{letter: "N", value: 1, x: nil, y: nil}
      ]
    end
    test "append_remaining should not create set invalid plays (not in dictionary)", state do
      player = state[:game] |> Map.get(:player_1)
      tiles_in_tray = [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "X", value: 1},
      ]
      player = player |> Map.merge(%{tiles_in_tray: tiles_in_tray})
      game = state[:game] |> Map.merge(%{player_1: player})
      start_yx = [0, 2]
      word_start = ["A", "L"]
      play = PlayAssembler.create(game, %{
        direction: :y,
        player_key: :player_1,
        start_yx: start_yx,
        word_start: word_start,
      })

      plays = PlayAssembler.append_remaining(game, play, [])
      assert Enum.count(plays) == 0
    end
    test "append_remaining should create set of plays (with the remaining tiles = 1 - valid)", state do
      player = state[:game] |> Map.get(:player_1)
      tiles_in_tray = [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
      ]
      player = player |> Map.merge(%{tiles_in_tray: tiles_in_tray})
      game = state[:game] |> Map.merge(%{player_1: player})
      start_yx = [0, 0]
      word_start = ["A", "L"]
      play = PlayAssembler.create(game, %{
        direction: :y,
        player_key: :player_1,
        start_yx: start_yx,
        word_start: word_start,
      })
      plays = PlayAssembler.append_remaining(game, play, [])
      assert Enum.count(plays) == 2
      play = List.first(plays)
      assert play.tiles_in_play == [
        %Wordza.GameTile{letter: "A", value: 1, y: 0, x: 0},
        %Wordza.GameTile{letter: "L", value: 1, y: 1, x: 0},
        # skipping y=2, already on board
        %Wordza.GameTile{letter: "N", value: 1, y: 3, x: 0}
      ]
      assert play.errors == []
      assert play.valid == true
      assert play.score == 12

      # TODO this is bullshit - it should limit to only 1 copy of any play
      play = List.last(plays)
      assert play.tiles_in_play == [
        %Wordza.GameTile{letter: "A", value: 1, y: 0, x: 0},
        %Wordza.GameTile{letter: "L", value: 1, y: 1, x: 0},
        # skipping y=2, already on board
        %Wordza.GameTile{letter: "N", value: 1, y: 3, x: 0}
      ]
      assert play.errors == []
      assert play.valid == true
      assert play.score == 12

    end
    test "next_unplayed_yx should allow y=3 (y=2 was played)", state do
      play = PlayAssembler.create(state[:game], %{
        direction: :y,
        player_key: :player_1,
        start_yx: [0, 0],
        word_start: ["A", "L"],
      })
      assert PlayAssembler.next_unplayed_yx(play) == [3, 0]
    end
    test "next_unplayed_yx should allow y=4 (y=2&3 were played)", state do
      board = state[:game]
              |> Map.get(:board)
              |> GameBoard.add_letters([%{letter: "L", y: 3, x: 0, value: 1}])
      game = state[:game] |> Map.merge(%{board: board})
      play = PlayAssembler.create(game, %{
        direction: :y,
        player_key: :player_1,
        start_yx: [0, 0],
        word_start: ["A", "L"],
      })
      assert PlayAssembler.next_unplayed_yx(play) == [4, 0]
    end
  end
end

