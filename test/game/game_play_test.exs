defmodule GamePlayTest do
  use ExUnit.Case
  doctest Wordza.GamePlay
  alias Wordza.GamePlay

  test "create a play" do
    word = [
      ["a", 0, 2],
      ["l", 1, 2],
      ["l", 2, 2],
    ]
    assert GamePlay.create(:player_1, word) == %GamePlay{
      player_key: :player_1,
      letters_yx: word,
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
      word = [
        ["A", 0, 2],
        ["L", 1, 2],
        ["L", 2, 2],
      ]
      play = GamePlay.create(:player_1, word)
      {:ok, play: play, game: game, player: player}
    end

    test "verify a play: all on mock game :start", state do
      play = GamePlay.verify(state[:play], state[:game])
      assert play.valid == true
      assert play.errors == []
      assert play.letters_in_tray_after_play == ["D", "N", "N", "A"]
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

    test "verify_letters_in_tray (good)", state do
      play = GamePlay.verify_letters_in_tray(state[:play], state[:game])
      assert get_errors(play) == []
      assert play.letters_in_tray_after_play == ["D", "N", "N", "A"]
    end
    test "verify_letters_in_tray (bad)", state do
      play = Map.merge(state[:play], %{letters_yx: [["N", 0, 0], ["O", 0, 1]]})
      assert get_errors(
        GamePlay.verify_letters_in_tray(play, state[:game])
      ) == ["Tiles not in your tray"]
      # ensure it does not change the letters_in_tray_after_play (since it did not pass)
      assert Map.get(
        GamePlay.verify_letters_in_tray(play, state[:game]),
        :letters_in_tray_after_play
      ) == play.letters_in_tray_after_play
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
    test "verify_letters_form_full_words (good - new=only word)", state do
      assert get_errors(
        GamePlay.verify_letters_form_full_words(state[:play], state[:game])
      ) == []
    end
    test "verify_letters_form_full_words (good - all valid words)", state do
      play = Map.merge(state[:play], %{letters_yx: [
        ["A", 0, 2],
        ["L", 1, 2],
        ["A", 2, 2],
        ["N", 3, 2],
      ]})
      board = state[:game]
              |> Map.get(:board)
              |> put_in([1, 0, :letter], "A")
              |> put_in([1, 1, :letter], "L")
      game = Map.merge(state[:game], %{board: board})
      assert get_errors(
        GamePlay.verify_letters_form_full_words(play, game)
      ) == []
    end
    test "verify_letters_form_full_words (bad - several invalid words)", state do
      play = Map.merge(state[:play], %{letters_yx: [["N", 0, 0], ["O", 0, 1]]})
      board = state[:game]
              |> Map.get(:board)
              |> put_in([1, 0, :letter], "A")
              |> put_in([1, 1, :letter], "L")
      game = Map.merge(state[:game], %{board: board})
      assert get_errors(
        GamePlay.verify_letters_form_full_words(play, game)
      ) == ["Not In Dictionary, unknown words: NA, OL, NO"]
    end
    test "verify_letters_form_full_words (bad - single invalid word)", state do
      play = Map.merge(state[:play], %{letters_yx: [
        ["A", 0, 2],
        ["L", 1, 2],
        ["A", 2, 2],
        ["N", 3, 2],
        ["J", 4, 2],
      ]})
      board = state[:game]
              |> Map.get(:board)
              |> put_in([1, 0, :letter], "A")
              |> put_in([1, 1, :letter], "L")
      game = Map.merge(state[:game], %{board: board})
      assert get_errors(
        GamePlay.verify_letters_form_full_words(play, game)
      ) == ["Not In Dictionary, unknown word: ALANJ"]
    end

  end

end
