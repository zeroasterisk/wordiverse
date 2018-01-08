defmodule PlayAssemblerTest do
  use ExUnit.Case
  # doctest Wordza.PlayAssembler
  alias Wordza.PlayAssembler
  alias Wordza.BotBits
  alias Wordza.GameBoard
  alias Wordza.GameTiles

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      game = Wordza.GameInstance.create(:mock, :player_1, :player_2)
      played_yx = [["A", 2, 0], ["L", 2, 1], ["L", 2, 2]] # <-- played already "ALL" horiz
      game = game |> Map.merge(%{
        board: game
        |> Map.get(:board)
        |> GameBoard.add_letters_xy(played_yx),
        player_1: game
        |> Map.get(:player_1)
        |> Map.merge(%{tiles_in_tray: Wordza.GameTiles.create(:mock_tray)}),
      })
      {:ok, game: game}
    end

    test "create_y should create nil for unplayable word 'A' (wrong length)", state do
      start_yx = [0, 2]
      word_start = ["A"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      assert play.valid == false
      assert play.errors == ["Tiles must touch an existing tile"]
    end
    test "create_y should create nil for unplayable word 'ALL' (wrong length)", state do
      start_yx = [0, 2]
      word_start = ["A", "L", "L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      assert play.valid == false
      assert play.errors == ["Tiles may not overlap"]
    end
    test "create_y should create nil for unplayable word 'BS' (not in tray)", state do
      start_yx = [0, 2]
      word_start = ["B", "S"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      assert play.valid == false
      assert play.errors == ["Tiles not in your tray"]
    end
    test "create_y should create nil for unplayable word 'ALL' (no played letter, in y direction)", state do
      start_yx = [0, 3]
      word_start = ["A", "L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      assert play.valid == false
      assert play.errors == ["Tiles must touch an existing tile"]
    end
    test "create_y should create a play for playable word 'AL'", state do
      start_yx = [0, 2]
      word_start = ["A", "L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      assert play.valid == true
      assert play.errors == []
      assert play.letters_in_tray_after_play == [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
      ]
      assert play.letters_yx == [["A", 0, 2], ["L", 1, 2]]
      # IO.inspect play
    end
    # test "create_y should create a play for a word 'L' after the already played 'A'", state do
    #   start_yx = [3, 0]
    #   word_start = ["L"]
    #   assert PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start) == %Wordza.PlayAssembler{
    #     board: state[:game][:board],
    #     player_key: :player_1,
    #     start_yx: [0, 2],
    #     dir: :y,
    #     letters_yx: [
    #       ["L", 3, 0]
    #     ],
    #     letters_left: [
    #       %Wordza.GameTile{letter: "A", value: 1},
    #       %Wordza.GameTile{letter: "L", value: 1},
    #       %Wordza.GameTile{letter: "N", value: 1}
    #     ],
    #     word: ["A", "L"],
    #     word_start: ["L"]
    #   }
    # end
  end
end

