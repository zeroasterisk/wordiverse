defmodule GamePlayTest do
  use ExUnit.Case
  doctest Wordza.GamePlay
  alias Wordza.GamePlay

  test "create a play" do
    letters_yx = [
      ["A", 0, 2],
      ["L", 1, 2],
      ["L", 2, 2],
    ]
    assert GamePlay.create(:player_1, letters_yx) == %GamePlay{
      player_key: :player_1,
      letters_yx: letters_yx,
      direction: :y,
      score: 0,
      valid: nil,
      errors: [],
    }
  end

  describe "verifications" do
    defp get_errors(%GamePlay{errors: errors}), do: errors

    setup do
      Wordza.Dictionary.start_link(:mock)
      game = Wordza.GameInstance.create(:mock, :player_1, :player_2)
      tray = []
            |> Wordza.GameTiles.add("A", 1, 2)
            |> Wordza.GameTiles.add("L", 1, 2)
            |> Wordza.GameTiles.add("N", 1, 2)
            |> Wordza.GameTiles.add("D", 1, 1)
      player = Map.merge(game.player_1, %{tiles_in_tray: tray})
      game = Map.put(game, :player_1, player)
      letters_yx = [
        ["A", 0, 2],
        ["L", 1, 2],
        ["L", 2, 2],
      ]
      play = GamePlay.create(:player_1, letters_yx)
      {:ok, play: play, game: game, player: player}
    end

    test "verify a play: all on mock game :start", state do
      play = state[:play] |> GamePlay.verify(state[:game])
      assert play.valid == true
      assert play.errors == []
      assert play.tiles_in_tray == [
        %Wordza.GameTile{letter: "D", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
        %Wordza.GameTile{letter: "A", value: 1},
      ]
    end

    test "verify_letters_are_valid (good)", state do
      assert get_errors(
        GamePlay.verify_letters_are_valid(state[:play])
      ) == []
    end
    test "verify_letters_are_valid (bad: empty)", state do
      play = Map.merge(state[:play], %{letters_yx: []})
      assert get_errors(
        GamePlay.verify_letters_are_valid(play)
      ) == ["You have not played any letters"]
    end
    test "verify_letters_are_valid (bad: non-letter)", state do
      play = Map.merge(state[:play], %{letters_yx: [[:a, 0, 0]]})
      assert get_errors(
        GamePlay.verify_letters_are_valid(play)
      ) == ["You have played invalid letters"]
      assert get_errors(
        GamePlay.verify(play, state[:game])
      ) == ["You have played invalid letters"]
    end
    test "verify_letters_are_valid (bad: non-numeric x/y)", state do
      play = Map.merge(state[:play], %{letters_yx: [["A", 0.5, 0.5]]})
      assert get_errors(
        GamePlay.verify_letters_are_valid(play)
      ) == ["You have played invalid letters"]
      assert get_errors(
        GamePlay.verify(play, state[:game])
      ) == ["You have played invalid letters"]
    end
    test "verify_letters_are_single_direction (good)", state do
      assert get_errors(
        GamePlay.verify_letters_are_single_direction(state[:play])
      ) == []
    end
    test "verify_letters_are_single_direction (bad: diagonal)", state do
      play = Map.merge(state[:play], %{letters_yx: [["A", 0, 0], ["L", 1, 1]]})
      assert get_errors(
        GamePlay.verify_letters_are_single_direction(play)
      ) == ["You must play all tiles in a single row or column"]
      assert get_errors(
        GamePlay.verify(play, state[:game])
      ) == ["You must play all tiles in a single row or column"]
    end

    ### these need the game, more complex, need board or player

    test "verify_letters_are_on_board (good)", state do
      assert get_errors(
        GamePlay.verify_letters_are_on_board(state[:play], state[:game])
      ) == []
    end
    test "verify_letters_are_on_board (bad, -1 y)", state do
      play = state[:play] |> Map.merge(%{letters_yx: [["N", -1, 0]]})
      assert get_errors(
        GamePlay.verify_letters_are_on_board(play, state[:game])
      ) == ["Tiles must be played on the board"]
    end
    test "verify_letters_are_on_board (bad, -1 x)", state do
      play = state[:play] |> Map.merge(%{letters_yx: [["N", 0, -1]]})
      assert get_errors(
        GamePlay.verify_letters_are_on_board(play, state[:game])
      ) == ["Tiles must be played on the board"]
    end
    test "verify_letters_are_on_board (bad, 5 y)", state do
      play = state[:play] |> Map.merge(%{letters_yx: [["N", 5, 0]]})
      assert get_errors(
        GamePlay.verify_letters_are_on_board(play, state[:game])
      ) == ["Tiles must be played on the board"]
    end
    test "verify_letters_are_on_board (bad, 5 x)", state do
      play = state[:play] |> Map.merge(%{letters_yx: [["N", 0, 5]]})
      assert get_errors(
        GamePlay.verify_letters_are_on_board(play, state[:game])
      ) == ["Tiles must be played on the board"]
    end

    test "verify_letters_in_tray (good)", state do
      play = state[:play]
             |> GamePlay.assign_letters(state[:game])
             |> GamePlay.verify_letters_in_tray(state[:game])
      assert get_errors(play) == []
      assert play.tiles_in_play == [
        %Wordza.GameTile{value: 1, letter: "A", x: 2, y: 0},
        %Wordza.GameTile{value: 1, letter: "L", x: 2, y: 1},
        %Wordza.GameTile{value: 1, letter: "L", x: 2, y: 2},
      ]
      assert play.tiles_in_tray == [
        %Wordza.GameTile{letter: "D", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
        %Wordza.GameTile{letter: "A", value: 1},
      ]
    end
    test "verify_letters_in_tray (bad)", state do
      play = state[:play]
             |> Map.merge(%{letters_yx: [["N", 0, 0], ["O", 0, 1]]})
             |> GamePlay.assign_letters(state[:game])
             |> GamePlay.verify_letters_in_tray(state[:game])
      assert get_errors(
        GamePlay.verify_letters_in_tray(play, state[:game])
      ) == ["Tiles not in your tray"]
      # ensure it does not change the tiles_in_tray (since it did not pass)
      assert play.tiles_in_play == []
      assert Map.get(
        GamePlay.verify_letters_in_tray(play, state[:game]),
        :tiles_in_tray
      ) == play.tiles_in_tray
    end

    test "verify_letters_do_not_overlap (good - new play)", state do
      assert get_errors(
        GamePlay.verify_letters_do_not_overlap(state[:play], state[:game])
      ) == []
    end
    test "verify_letters_do_not_overlap (good - no overlap)", state do
      board = state[:game]
              |> Map.get(:board)
              |> put_in([0, 1, :letter], "A") # <-- next to played letters
              |> put_in([1, 1, :letter], "A")
              |> put_in([2, 1, :letter], "A")
      game = Map.merge(state[:game], %{board: board})
      assert get_errors(
        GamePlay.verify_letters_do_not_overlap(state[:play], game)
      ) == []
    end
    test "verify_letters_do_not_overlap (bad has overlap)", state do
      board = state[:game]
              |> Map.get(:board)
              |> put_in([2, 2, :letter], "A") # <-- center square only
      game = Map.merge(state[:game], %{board: board})
      assert get_errors(
        GamePlay.verify_letters_do_not_overlap(state[:play], game)
      ) == ["Tiles may not overlap"]
    end
    test "verify_letters_touch (good - new play)", state do
      assert get_errors(
        GamePlay.verify_letters_touch(state[:play], state[:game])
      ) == []
    end
    test "verify_letters_touch (good - adjacent play)", state do
      board = state[:game]
              |> Map.get(:board)
              |> put_in([0, 1, :letter], "A") # <-- next to played letters
      game = Map.merge(state[:game], %{board: board})
      assert get_errors(
        GamePlay.verify_letters_touch(state[:play], game)
      ) == []
    end
    test "verify_letters_touch (bad no next-tile)", state do
      board = state[:game]
              |> Map.get(:board)
              |> put_in([0, 0, :letter], "A") # <-- top-left, not touching anything
      game = Map.merge(state[:game], %{board: board})
      assert get_errors(
        GamePlay.verify_letters_touch(state[:play], game)
      ) == ["Tiles must touch an existing tile"]
    end
    test "verify_letters_cover_start (good - new play)", state do
      play = GamePlay.verify_letters_cover_start(state[:play], state[:game])
      assert get_errors(play) == []
    end
    test "verify_letters_cover_start (good - not first word, ignored)", state do
      play = Map.merge(state[:play], %{letters_yx: [["N", 0, 0], ["O", 0, 1]]})
      board = state[:game]
              |> Map.get(:board)
              |> put_in([4, 4, :letter], "A") # <-- bottom-right, not touching anything
      game = Map.merge(state[:game], %{board: board})
      assert get_errors(
        GamePlay.verify_letters_cover_start(play, game)
      ) == []
    end
    test "verify_letters_cover_start (bad not covering center, not first word)", state do
      play = Map.merge(state[:play], %{letters_yx: [["N", 0, 0], ["O", 0, 1]]})
      board = Map.get(state[:game], :board)
      game = Map.merge(state[:game], %{board: board})
      assert get_errors(
        GamePlay.verify_letters_cover_start(play, game)
      ) == ["Tiles must cover the center square to start"]
    end
    test "verify_words_are_full_words (good - new=only word)", state do
      assert get_errors(
        GamePlay.verify_words_are_full_words(state[:play], state[:game])
      ) == []
    end
    test "verify_words_are_full_words (good - all valid words)", state do
      board = state[:game]
              |> Map.get(:board)
              |> Wordza.GameBoard.add_letters([
                %{y: 0, x: 3, letter: "L", value: 1},
                %{y: 0, x: 4, letter: "L", value: 1},
              ])
      game = Map.merge(state[:game], %{board: board})
      play = state[:play]
             |> Map.merge(%{letters_yx: [
               ["A", 0, 2],
               ["L", 1, 2],
               ["A", 2, 2],
               ["N", 3, 2],
             ]})
             |> GamePlay.assign_letters(game)
             |> GamePlay.assign_words(game)

      assert play.words == [
        [
          %{x: 2, y: 0, bonus: :tl, letter: "A", value: 1},
          %{x: 2, y: 1, bonus: nil, letter: "L", value: 1},
          %{x: 2, y: 2, bonus: :st, letter: "A", value: 1},
          %{x: 2, y: 3, bonus: nil, letter: "N", value: 1},
        ],
        [
          %{y: 0, x: 2, value: 1, bonus: :tl, letter: "A"},
          %{y: 0, x: 3, value: 1, bonus: nil, letter: "L"},
          %{y: 0, x: 4, value: 1, bonus: :tw, letter: "L"},
        ],
      ]
      assert get_errors(
        GamePlay.verify_words_are_full_words(play, game)
      ) == []
    end
    test "verify_words_are_full_words (bad - single invalid word)", state do
      board = state[:game]
              |> Map.get(:board)
              |> Wordza.GameBoard.add_letters([
                %{y: 1, x: 0, letter: "A", value: 1},
                %{y: 1, x: 1, letter: "L", value: 1},
                %{y: 3, x: 2, letter: "J", value: 1},
                %{y: 3, x: 3, letter: "J", value: 1},
              ])
      game = Map.merge(state[:game], %{board: board})
      play = state[:play]
             |> Map.merge(%{letters_yx: [
               ["A", 0, 2],
               ["L", 1, 2],
               ["L", 2, 2],
             ]})
             |> GamePlay.assign_letters(game)
             |> GamePlay.assign_words(game)

      assert get_errors(
        GamePlay.verify_words_are_full_words(play, game)
      ) == ["Not In Dictionary, unknown word: ALLJ"]
    end
    test "verify_words_are_full_words (bad - several invalid words)", state do
      board = state[:game]
              |> Map.get(:board)
              |> Wordza.GameBoard.add_letters([
                %{y: 1, x: 0, letter: "A", value: 1},
                %{y: 1, x: 1, letter: "L", value: 1},
              ])
      game = Map.merge(state[:game], %{board: board})
      play = state[:play]
             |> Map.merge(%{letters_yx: [
               ["D", 0, 0],
               ["N", 0, 1],
             ]})
             |> GamePlay.assign_letters(game)
             |> GamePlay.assign_words(game)

      assert get_errors(
        GamePlay.verify_words_are_full_words(play, game)
      ) == ["Not In Dictionary, unknown words: DA, NL, DN"]
    end

  end

end
