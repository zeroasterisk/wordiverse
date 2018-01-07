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
      played_yx = [["A", 2, 0], ["L", 2, 1], ["L", 2, 2]] # <-- played already "ALL" horiz
      bot = %{
        board: :mock |> GameBoard.create() |> GameBoard.add_letters_xy(played_yx),
        player_key: :player_1,
        tiles_in_tray: Wordza.GameTiles.create(:mock_tray),
      }
      {:ok, bot: bot}
    end

    test "create_y should create nil for unplayable word 'A' (wrong length)", state do
      start_yx = [0, 2]
      word_start = ["A"]
      assert PlayAssembler.create_y(state[:bot], start_yx, word_start) == nil
    end
    test "create_y should create nil for unplayable word 'ALL' (wrong length)", state do
      start_yx = [0, 2]
      word_start = ["A", "L", "L"]
      assert PlayAssembler.create_y(state[:bot], start_yx, word_start) == nil
    end
    test "create_y should create nil for unplayable word 'BS' (not in tray)", state do
      start_yx = [0, 2]
      word_start = ["B", "S"]
      assert PlayAssembler.create_y(state[:bot], start_yx, word_start) == nil
    end
    test "create_y should create nil for unplayable word 'ALL' (no played letter, in y direction)", state do
      start_yx = [0, 3]
      word_start = ["A", "L"]
      assert PlayAssembler.create_y(state[:bot], start_yx, word_start) == nil
    end
    test "create_y should create a play for playable word 'AL'", state do
      start_yx = [0, 2]
      word_start = ["A", "L"]
      assert PlayAssembler.create_y(state[:bot], start_yx, word_start) == %Wordza.PlayAssembler{
        board: state[:bot][:board],
        player_key: :player_1,
        start_yx: [0, 2],
        dir: :y,
        letters_yx: [
          ["A", 0, 2],
          ["L", 1, 2]
        ],
        letters_left: [
          %Wordza.GameTile{letter: "A", value: 1},
          %Wordza.GameTile{letter: "L", value: 1},
          %Wordza.GameTile{letter: "N", value: 1}
        ],
        word: ["A", "L", "L"],
        word_start: ["A", "L"]
      }
    end
  end
end

