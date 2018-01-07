defmodule BotBitsTest do
  use ExUnit.Case
  doctest Wordza.BotBits
  alias Wordza.BotBits
  alias Wordza.GameBoard
  alias Wordza.GameTiles

  test "start_yx_playable is false, if already played square" do
    board = GameBoard.create(:scrabble)
    |> put_in([9, 7, :letter], "a")
    |> put_in([9, 8, :letter], "a")
    |> put_in([9, 9, :letter], "a")
    tiles = GameTiles.add([], "a", 1, 7)
    assert BotBits.start_yx_possible?(board, 9, 9, tiles) == false
  end

  test "start_yx_playable is false, if no overlap within 7 tiles of played word" do
    board = GameBoard.create(:scrabble)
    |> put_in([9, 7, :letter], "a")
    |> put_in([9, 8, :letter], "a")
    |> put_in([9, 9, :letter], "a")
    tiles = GameTiles.add([], "a", 1, 7)
    # totally alone
    assert BotBits.start_yx_possible?(board, 0, 0, tiles) == false
    # too far above
    assert BotBits.start_yx_possible?(board, 0, 8, tiles) == false
    # below a valid tile (not a valid start)
    assert BotBits.start_yx_possible?(board, 10, 8, tiles) == false
  end

  test "start_yx_playable is false, if no overlap within 3 tiles of played word" do
    board = GameBoard.create(:scrabble)
    |> put_in([9, 7, :letter], "a")
    |> put_in([9, 8, :letter], "a")
    |> put_in([9, 9, :letter], "a")
    tiles = GameTiles.add([], "a", 1, 3)
    # 4 square above, but only 3 in tray
    assert BotBits.start_yx_possible?(board, 4, 7, tiles) == false
  end

  test "start_yx_playable is true, if valid" do
    board = GameBoard.create(:scrabble)
    |> put_in([9, 7, :letter], "a")
    |> put_in([9, 8, :letter], "a")
    |> put_in([9, 9, :letter], "a")
    tiles = GameTiles.add([], "a", 1, 7)
    # 7 square above, 7 in tray
    assert BotBits.start_yx_possible?(board, 2, 7, tiles) == true
  end

  test "get_all_word_starts should return every combination of words for letters w/ :mock" do
    {:ok, _pid} = Wordza.Dictionary.start_link(:mock)
    letters = ["L", "B", "D", "A", "N", "A", "L"]
    assert Wordza.BotBits.get_all_word_starts(letters, :mock) == [
      ["A"],
      ["A", "L"],
      ["A", "L", "A"],
      ["A", "L", "A", "N"],
      ["A", "L", "L"],
    ]
  end

  test "get_all_word_starts should return EVERY combination of words for letters + ? w/ :mock" do
    {:ok, _pid} = Wordza.Dictionary.start_link(:mock)
    letters = ["L", "A", "N", "?"]
    assert Wordza.BotBits.get_all_word_starts(letters, :mock) == [
      ["A"],
      ["A", "L"],
      ["A", "L", "A"],
      ["A", "L", "A", "N"],
      ["A", "L", "L"],
    ]
  end

  # test "get_all_word_starts should return EVERY combination of words for letters + ? + ? w/ :mock" do
  #   {:ok, _pid} = Wordza.Dictionary.start_link(:mock)
  #   letters = ["L", "A", "?", "?"]
  #   assert Wordza.BotBits.get_all_word_starts(letters, :mock) == [
  #     ["A"],
  #     ["A", "L"],
  #     ["A", "L", "A"],
  #     ["A", "L", "A", "N"],
  #     ["A", "L", "L"],
  #   ]
  # end

end
