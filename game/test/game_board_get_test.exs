defmodule GameBoardGetTest do
  use ExUnit.Case
  doctest Wordiverse.GameBoardGet

  test "touching should return adjacent squares for all 4 directions if not edge" do
    board = Wordiverse.GameBoard.create_board(15, 15) |> fill_abcs()
    assert Wordiverse.GameBoardGet.touching(board, 5, 5) == [
      %{bonus: nil, letter: "J", y: 4, x: 5}, # top (y-1)
      %{bonus: nil, letter: "L", y: 5, x: 6}, # right (x+1)
      %{bonus: nil, letter: "L", y: 6, x: 5}, # bottom (y+1)
      %{bonus: nil, letter: "J", y: 5, x: 4}, # left (x-1)
    ]
  end
  test "touching should return adjacent squares for only 3 directions if edge" do
    board = Wordiverse.GameBoard.create_board(15, 15) |> fill_abcs()
    assert Wordiverse.GameBoardGet.touching(board, 0, 0) == [
      %{bonus: nil, letter: "B", y: 0, x: 1}, # right (x+1)
      %{bonus: nil, letter: "B", y: 1, x: 0}, # bottom (y+1)
    ]
    assert Wordiverse.GameBoardGet.touching(board, 0, 7) == [
      %{bonus: nil, letter: "I", y: 0, x: 8},
      %{bonus: nil, letter: "I", y: 1, x: 7},
      %{bonus: nil, letter: "G", y: 0, x: 6},
    ]
    assert Wordiverse.GameBoardGet.touching(board, 14, 7) == [
      %{bonus: nil, letter: "U", y: 13, x: 7},
      %{bonus: nil, letter: "W", y: 14, x: 8},
      %{bonus: nil, letter: "U", y: 14, x: 6},
    ]
  end

  test "touching_words should return all col/row for letters provided (high,so)" do
    letters_yx = [["S", 4, 1], ["O", 4, 2]]
    board = board_high_wide() |> Wordiverse.GameBoard.add_letters_xy(letters_yx)
    assert Wordiverse.GameBoardGet.touching_words(board, letters_yx) == [
      [
        %{bonus: nil, letter: "H", y: 0, x: 1},
        %{bonus: nil, letter: "I", y: 1, x: 1},
        %{bonus: nil, letter: "G", y: 2, x: 1},
        %{bonus: nil, letter: "H", y: 3, x: 1},
        %{bonus: nil, letter: "S", y: 4, x: 1},
      ],
      [
        %{bonus: nil, letter: "S", y: 4, x: 1},
        %{bonus: nil, letter: "O", y: 4, x: 2},
      ]
    ]
  end
  test "touching_words should return all col/row for letters provided (wide,so)" do
    letters_yx = [["S", 1, 4], ["O", 2, 4]]
    board = board_high_wide() |> Wordiverse.GameBoard.add_letters_xy(letters_yx)
    assert Wordiverse.GameBoardGet.touching_words(board, letters_yx) == [
      [
        %{bonus: nil, letter: "S", y: 1, x: 4},
        %{bonus: nil, letter: "O", y: 2, x: 4},
      ],
      [
        %{bonus: nil, letter: "W", y: 1, x: 0},
        %{bonus: nil, letter: "I", y: 1, x: 1},
        %{bonus: nil, letter: "D", y: 1, x: 2},
        %{bonus: nil, letter: "E", y: 1, x: 3},
        %{bonus: nil, letter: "S", y: 1, x: 4},
      ],
    ]
  end
  test "word_for_y finds all letters in 'word' for any point in column" do
    letters_yx = [["S", 4, 1], ["O", 4, 2]]
    board = board_high_wide() |> Wordiverse.GameBoard.add_letters_xy(letters_yx)

    assert Wordiverse.GameBoardGet.word_for_y(board, 4, 1) == [
      %{bonus: nil, letter: "H", y: 0, x: 1},
      %{bonus: nil, letter: "I", y: 1, x: 1},
      %{bonus: nil, letter: "G", y: 2, x: 1},
      %{bonus: nil, letter: "H", y: 3, x: 1},
      %{bonus: nil, letter: "S", y: 4, x: 1},
    ]
    assert Wordiverse.GameBoardGet.word_for_y(board, 1, 1) == [
      %{bonus: nil, letter: "H", y: 0, x: 1},
      %{bonus: nil, letter: "I", y: 1, x: 1},
      %{bonus: nil, letter: "G", y: 2, x: 1},
      %{bonus: nil, letter: "H", y: 3, x: 1},
      %{bonus: nil, letter: "S", y: 4, x: 1},
    ]
  end
  test "word_for_y stops on nil" do
    board = board_high_wide() |> put_in([0, 1, :letter], nil)
    assert Wordiverse.GameBoardGet.word_for_y(board, 3, 1) == [
      %{bonus: nil, letter: "I", y: 1, x: 1},
      %{bonus: nil, letter: "G", y: 2, x: 1},
      %{bonus: nil, letter: "H", y: 3, x: 1},
    ]
    assert Wordiverse.GameBoardGet.word_for_y(board, 1, 1) == [
      %{bonus: nil, letter: "I", y: 1, x: 1},
      %{bonus: nil, letter: "G", y: 2, x: 1},
      %{bonus: nil, letter: "H", y: 3, x: 1},
    ]
  end
  test "word_for_x finds all letters in 'word' for any point in column" do
    letters_yx = [["S", 4, 1], ["O", 4, 2]]
    board = board_high_wide() |> Wordiverse.GameBoard.add_letters_xy(letters_yx)

    assert Wordiverse.GameBoardGet.word_for_x(board, 4, 1) == [
      %{bonus: nil, letter: "S", y: 4, x: 1},
      %{bonus: nil, letter: "O", y: 4, x: 2},
    ]
    assert Wordiverse.GameBoardGet.word_for_x(board, 1, 1) == [
      %{bonus: nil, letter: "W", y: 1, x: 0},
      %{bonus: nil, letter: "I", y: 1, x: 1},
      %{bonus: nil, letter: "D", y: 1, x: 2},
      %{bonus: nil, letter: "E", y: 1, x: 3},
    ]
  end
  test "word_for_x stops on nil" do
    board = board_high_wide() |> put_in([1, 0, :letter], nil)
    assert Wordiverse.GameBoardGet.word_for_x(board, 1, 1) == [
      %{bonus: nil, letter: "I", y: 1, x: 1},
      %{bonus: nil, letter: "D", y: 1, x: 2},
      %{bonus: nil, letter: "E", y: 1, x: 3},
    ]
  end

  # sometimes it's usefule to fill a board with letters
  defp fill_abcs(board) do
    abcs = Enum.map(?a..?z, fn(x) -> <<x :: utf8>> end)
           |> Enum.map(&String.upcase/1)
    count_y = board |> Map.keys() |> Enum.count()
    count_x = board[0] |> Map.keys() |> Enum.count()
    fill_abcs(board, abcs, count_y - 1, count_x - 1)
  end
  defp fill_abcs(board, abcs, 0, 0) do
    # done...
    board
    |> put_in([0, 0, :letter], Enum.at(abcs, 0))
  end
  defp fill_abcs(board, abcs, y, -1) do
    # nope - too far, move up a row
    count_x = board[0] |> Map.keys() |> Enum.count()
    board
    |> fill_abcs(abcs, y - 1, count_x - 1)
  end
  defp fill_abcs(board, abcs, y, x) do
    board
    |> put_in([y, x, :letter], Enum.at(abcs, rem((x + y), 26)))
    # next, move left in same row
    |> fill_abcs(abcs, y, x - 1)
  end

  defp board_high_wide() do
    Wordiverse.GameBoard.create_board(7, 7)
    |> put_in([1, 0, :letter], "W")
    |> put_in([1, 1, :letter], "I")
    |> put_in([1, 2, :letter], "D")
    |> put_in([1, 3, :letter], "E")
    |> put_in([0, 1, :letter], "H")
    |> put_in([2, 1, :letter], "G")
    |> put_in([3, 1, :letter], "H")
  end
end
