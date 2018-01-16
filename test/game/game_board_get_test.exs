defmodule GameBoardGetTest do
  use ExUnit.Case
  doctest Wordza.GameBoardGet

  test "touching should return adjacent squares for all 4 directions if not edge" do
    board = Wordza.GameBoard.create_board(15, 15) |> fill_abcs()
    assert Wordza.GameBoardGet.touching(board, 5, 5) == [
      %{bonus: nil, letter: "J", value: 1, y: 4, x: 5}, # top (y-1)
      %{bonus: nil, letter: "L", value: 1, y: 5, x: 6}, # right (x+1)
      %{bonus: nil, letter: "L", value: 1, y: 6, x: 5}, # bottom (y+1)
      %{bonus: nil, letter: "J", value: 1, y: 5, x: 4}, # left (x-1)
    ]
  end
  test "touching should return adjacent squares for only 3 directions if edge" do
    board = Wordza.GameBoard.create_board(15, 15) |> fill_abcs()
    assert Wordza.GameBoardGet.touching(board, 0, 0) == [
      %{bonus: nil, letter: "B", value: 1, y: 0, x: 1}, # right (x+1)
      %{bonus: nil, letter: "B", value: 1, y: 1, x: 0}, # bottom (y+1)
    ]
    assert Wordza.GameBoardGet.touching(board, 0, 7) == [
      %{bonus: nil, letter: "I", value: 1, y: 0, x: 8},
      %{bonus: nil, letter: "I", value: 1, y: 1, x: 7},
      %{bonus: nil, letter: "G", value: 1, y: 0, x: 6},
    ]
    assert Wordza.GameBoardGet.touching(board, 14, 7) == [
      %{bonus: nil, letter: "U", value: 1, y: 13, x: 7},
      %{bonus: nil, letter: "W", value: 1, y: 14, x: 8},
      %{bonus: nil, letter: "U", value: 1, y: 14, x: 6},
    ]
  end

  test "touching_words should return all col/row for letters provided (high,wide) [fake center play]" do
    tiles_in_play = [
      %{y: 1, x: 1, letter: "I", value: 1},
    ]
    board = board_high_wide() # I is already on the board...
    assert Wordza.GameBoardGet.touching_words(board, tiles_in_play) == [
      [
        %{bonus: nil, letter: "H", value: 1, y: 0, x: 1},
        %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
        %{bonus: nil, letter: "G", value: 1, y: 2, x: 1},
        %{bonus: nil, letter: "H", value: 1, y: 3, x: 1},
      ],
      [
        %{bonus: nil, letter: "W", value: 1, y: 1, x: 0},
        %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
        %{bonus: nil, letter: "D", value: 1, y: 1, x: 2},
        %{bonus: nil, letter: "E", value: 1, y: 1, x: 3},
      ]
    ]
  end
  test "touching_words will return nothing if we do not provide a list of tiles_in_play" do
    tiles_in_play = []
    board = board_high_wide()
    assert Wordza.GameBoardGet.touching_words(board, tiles_in_play) == []
  end
  test "touching_words should return all col/row for letters provided (ds,eo,gso) [funky nested cross]" do
    tiles_in_play = [
      %{letter: "S", value: 1, y: 2, x: 2},
      %{letter: "O", value: 1, y: 2, x: 3},
    ]
    board = board_high_wide() |> Wordza.GameBoard.add_letters(tiles_in_play)
    assert Wordza.GameBoardGet.touching_words(board, tiles_in_play) == [
      [
        %{bonus: nil, letter: "D", value: 1, y: 1, x: 2},
        %{bonus: nil, letter: "S", value: 1, y: 2, x: 2},
      ],
      [
        %{bonus: nil, letter: "E", value: 1, y: 1, x: 3},
        %{bonus: nil, letter: "O", value: 1, y: 2, x: 3},
      ],
      [
        %{bonus: nil, letter: "G", value: 1, y: 2, x: 1},
        %{bonus: nil, letter: "S", value: 1, y: 2, x: 2},
        %{bonus: nil, letter: "O", value: 1, y: 2, x: 3},
      ],
    ]
  end
  test "touching_words should return all col/row for letters provided (highsx,so) [span gap]" do
    tiles_in_play = [
      %{letter: "S", value: 1, y: 4, x: 1},
      %{letter: "O", value: 1, y: 4, x: 2},
    ]
    board = board_high_wide()
            |> Wordza.GameBoard.add_letters(tiles_in_play)
            |> Wordza.GameBoard.add_letters([
              %{y: 5, x: 0, letter: "X", value: 1},
              %{y: 5, x: 1, letter: "X", value: 1},
            ])
    assert Wordza.GameBoardGet.touching_words(board, tiles_in_play) == [
      [
        %{bonus: nil, letter: "H", value: 1, y: 0, x: 1},
        %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
        %{bonus: nil, letter: "G", value: 1, y: 2, x: 1},
        %{bonus: nil, letter: "H", value: 1, y: 3, x: 1},
        %{bonus: nil, letter: "S", value: 1, y: 4, x: 1},
        %{bonus: nil, letter: "X", value: 1, y: 5, x: 1},
      ],
      [
        %{bonus: nil, letter: "S", value: 1, y: 4, x: 1},
        %{bonus: nil, letter: "O", value: 1, y: 4, x: 2},
      ],
    ]
  end
  test "touching_words should return all col/row for letters provided (highsx,ox,so) [span gap, make grid]" do
    tiles_in_play = [
      %{letter: "S", value: 1, y: 4, x: 1},
      %{letter: "O", value: 1, y: 4, x: 2},
    ]
    board = board_high_wide()
            |> Wordza.GameBoard.add_letters(tiles_in_play)
            |> Wordza.GameBoard.add_letters([
              %{y: 5, x: 1, letter: "X", value: 1},
              %{y: 5, x: 2, letter: "X", value: 1},
            ])
    assert Wordza.GameBoardGet.touching_words(board, tiles_in_play) == [
      [
        %{bonus: nil, letter: "H", value: 1, y: 0, x: 1},
        %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
        %{bonus: nil, letter: "G", value: 1, y: 2, x: 1},
        %{bonus: nil, letter: "H", value: 1, y: 3, x: 1},
        %{bonus: nil, letter: "S", value: 1, y: 4, x: 1},
        %{bonus: nil, letter: "X", value: 1, y: 5, x: 1},
      ],
      [
        %{bonus: nil, letter: "O", value: 1, y: 4, x: 2},
        %{bonus: nil, letter: "X", value: 1, y: 5, x: 2},
      ],
      [
        %{bonus: nil, letter: "S", value: 1, y: 4, x: 1},
        %{bonus: nil, letter: "O", value: 1, y: 4, x: 2},
      ],
    ]
  end
  test "touching_words should return all col/row for letters provided (highsx,ox,soy) [span gap*2, make grid]" do
    tiles_in_play = [
      %{letter: "S", value: 1, y: 4, x: 1},
      %{letter: "O", value: 1, y: 4, x: 2},
    ]
    board = board_high_wide()
            |> Wordza.GameBoard.add_letters(tiles_in_play)
            |> Wordza.GameBoard.add_letters([
              %{y: 5, x: 1, letter: "X", value: 1},
              %{y: 5, x: 2, letter: "X", value: 1},
              %{y: 4, x: 3, letter: "Y", value: 1},
              %{y: 5, x: 3, letter: "Y", value: 1},
            ])
    assert Wordza.GameBoardGet.touching_words(board, tiles_in_play) == [
      [
        %{bonus: nil, letter: "H", value: 1, y: 0, x: 1},
        %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
        %{bonus: nil, letter: "G", value: 1, y: 2, x: 1},
        %{bonus: nil, letter: "H", value: 1, y: 3, x: 1},
        %{bonus: nil, letter: "S", value: 1, y: 4, x: 1},
        %{bonus: nil, letter: "X", value: 1, y: 5, x: 1},
      ],
      [
        %{bonus: nil, letter: "O", value: 1, y: 4, x: 2},
        %{bonus: nil, letter: "X", value: 1, y: 5, x: 2},
      ],
      [
        %{bonus: nil, letter: "S", value: 1, y: 4, x: 1},
        %{bonus: nil, letter: "O", value: 1, y: 4, x: 2},
        %{bonus: nil, letter: "Y", value: 1, y: 4, x: 3},
      ],
    ]
  end
  test "touching_words should return all col/row for letters provided (wide,so)" do
    tiles_in_play = [
      %{letter: "S", value: 1, y: 1, x: 4},
      %{letter: "O", value: 1, y: 2, x: 4},
    ]
    board = board_high_wide() |> Wordza.GameBoard.add_letters(tiles_in_play)
    assert Wordza.GameBoardGet.touching_words(board, tiles_in_play) == [
      [
        %{bonus: nil, letter: "S", value: 1, y: 1, x: 4},
        %{bonus: nil, letter: "O", value: 1, y: 2, x: 4},
      ],
      [
        %{bonus: nil, letter: "W", value: 1, y: 1, x: 0},
        %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
        %{bonus: nil, letter: "D", value: 1, y: 1, x: 2},
        %{bonus: nil, letter: "E", value: 1, y: 1, x: 3},
        %{bonus: nil, letter: "S", value: 1, y: 1, x: 4},
      ],
    ]
  end
  test "touching_words should return all col/row for letters provided (high,wide,so)" do
    tiles_in_play = [
      %{letter: "S", value: 1, y: 1, x: 4},
      %{letter: "O", value: 1, y: 2, x: 4},
    ]
    board = board_high_wide() |> Wordza.GameBoard.add_letters(tiles_in_play)
    assert Wordza.GameBoardGet.touching_words(board, tiles_in_play) == [
      [
        %{bonus: nil, letter: "S", value: 1, y: 1, x: 4},
        %{bonus: nil, letter: "O", value: 1, y: 2, x: 4},
      ],
      [
        %{bonus: nil, letter: "W", value: 1, y: 1, x: 0},
        %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
        %{bonus: nil, letter: "D", value: 1, y: 1, x: 2},
        %{bonus: nil, letter: "E", value: 1, y: 1, x: 3},
        %{bonus: nil, letter: "S", value: 1, y: 1, x: 4},
      ],
    ]
  end
  test "word_for_y finds all letters in 'word' for any point in column" do
    tiles_in_play = [
      %{letter: "S", value: 1, y: 4, x: 1},
      %{letter: "O", value: 1, y: 4, x: 2},
    ]
    board = board_high_wide() |> Wordza.GameBoard.add_letters(tiles_in_play)

    assert Wordza.GameBoardGet.word_for_y(board, 4, 1) == [
      %{bonus: nil, letter: "H", value: 1, y: 0, x: 1},
      %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
      %{bonus: nil, letter: "G", value: 1, y: 2, x: 1},
      %{bonus: nil, letter: "H", value: 1, y: 3, x: 1},
      %{bonus: nil, letter: "S", value: 1, y: 4, x: 1},
    ]
    assert Wordza.GameBoardGet.word_for_y(board, 1, 1) == [
      %{bonus: nil, letter: "H", value: 1, y: 0, x: 1},
      %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
      %{bonus: nil, letter: "G", value: 1, y: 2, x: 1},
      %{bonus: nil, letter: "H", value: 1, y: 3, x: 1},
      %{bonus: nil, letter: "S", value: 1, y: 4, x: 1},
    ]
  end
  test "word_for_y stops on nil" do
    board = board_high_wide() |> put_in([0, 1, :letter], nil)
    assert Wordza.GameBoardGet.word_for_y(board, 3, 1) == [
      %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
      %{bonus: nil, letter: "G", value: 1, y: 2, x: 1},
      %{bonus: nil, letter: "H", value: 1, y: 3, x: 1},
    ]
    assert Wordza.GameBoardGet.word_for_y(board, 1, 1) == [
      %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
      %{bonus: nil, letter: "G", value: 1, y: 2, x: 1},
      %{bonus: nil, letter: "H", value: 1, y: 3, x: 1},
    ]
  end
  test "word_for_x finds all letters in 'word' for any point in column" do
    tiles_in_play = [
      %{letter: "S", value: 1, y: 4, x: 1},
      %{letter: "O", value: 1, y: 4, x: 2},
    ]
    board = board_high_wide() |> Wordza.GameBoard.add_letters(tiles_in_play)

    assert Wordza.GameBoardGet.word_for_x(board, 4, 1) == [
      %{bonus: nil, letter: "S", value: 1, y: 4, x: 1},
      %{bonus: nil, letter: "O", value: 1, y: 4, x: 2},
    ]
    assert Wordza.GameBoardGet.word_for_x(board, 1, 1) == [
      %{bonus: nil, letter: "W", value: 1, y: 1, x: 0},
      %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
      %{bonus: nil, letter: "D", value: 1, y: 1, x: 2},
      %{bonus: nil, letter: "E", value: 1, y: 1, x: 3},
    ]
  end
  test "word_for_x stops on nil" do
    board = board_high_wide() |> put_in([1, 0, :letter], nil)
    assert Wordza.GameBoardGet.word_for_x(board, 1, 1) == [
      %{bonus: nil, letter: "I", value: 1, y: 1, x: 1},
      %{bonus: nil, letter: "D", value: 1, y: 1, x: 2},
      %{bonus: nil, letter: "E", value: 1, y: 1, x: 3},
    ]
  end
  test "word_for_x goes until the end of board" do
    tiles_in_play = [
      %{letter: "A", value: 1, y: 0, x: 0},
      %{letter: "B", value: 1, y: 0, x: 1},
      %{letter: "C", value: 1, y: 0, x: 2},
      %{letter: "D", value: 1, y: 0, x: 3},
      %{letter: "E", value: 1, y: 0, x: 4},
      %{letter: "F", value: 1, y: 0, x: 5},
      %{letter: "G", value: 1, y: 0, x: 6},
    ]
    board = board_high_wide() |> Wordza.GameBoard.add_letters(tiles_in_play)
    assert Wordza.GameBoardGet.word_for_x(board, 0, 0) == [
      %{letter: "A", value: 1, y: 0, x: 0, bonus: nil},
      %{letter: "B", value: 1, y: 0, x: 1, bonus: nil},
      %{letter: "C", value: 1, y: 0, x: 2, bonus: nil},
      %{letter: "D", value: 1, y: 0, x: 3, bonus: nil},
      %{letter: "E", value: 1, y: 0, x: 4, bonus: nil},
      %{letter: "F", value: 1, y: 0, x: 5, bonus: nil},
      %{letter: "G", value: 1, y: 0, x: 6, bonus: nil},
    ]
    # same regardless of starting position
    assert Wordza.GameBoardGet.word_for_x(board, 0, 2) == Wordza.GameBoardGet.word_for_x(board, 0, 0)
    assert Wordza.GameBoardGet.word_for_x(board, 0, 4) == Wordza.GameBoardGet.word_for_x(board, 0, 0)
    assert Wordza.GameBoardGet.word_for_x(board, 0, 6) == Wordza.GameBoardGet.word_for_x(board, 0, 0)
  end
  test "word_for_y goes until the end of board" do
    tiles_in_play = [
      %{letter: "A", value: 1, x: 0, y: 0},
      %{letter: "B", value: 1, x: 0, y: 1},
      %{letter: "C", value: 1, x: 0, y: 2},
      %{letter: "D", value: 1, x: 0, y: 3},
      %{letter: "E", value: 1, x: 0, y: 4},
      %{letter: "F", value: 1, x: 0, y: 5},
      %{letter: "G", value: 1, x: 0, y: 6},
    ]
    board = board_high_wide() |> Wordza.GameBoard.add_letters(tiles_in_play)
    assert Wordza.GameBoardGet.word_for_y(board, 0, 0) == [
      %{letter: "A", value: 1, x: 0, y: 0, bonus: nil},
      %{letter: "B", value: 1, x: 0, y: 1, bonus: nil},
      %{letter: "C", value: 1, x: 0, y: 2, bonus: nil},
      %{letter: "D", value: 1, x: 0, y: 3, bonus: nil},
      %{letter: "E", value: 1, x: 0, y: 4, bonus: nil},
      %{letter: "F", value: 1, x: 0, y: 5, bonus: nil},
      %{letter: "G", value: 1, x: 0, y: 6, bonus: nil},
    ]
    # same regardless of starting position
    assert Wordza.GameBoardGet.word_for_y(board, 2, 0) == Wordza.GameBoardGet.word_for_y(board, 0, 0)
    assert Wordza.GameBoardGet.word_for_y(board, 4, 0) == Wordza.GameBoardGet.word_for_y(board, 0, 0)
    assert Wordza.GameBoardGet.word_for_y(board, 6, 0) == Wordza.GameBoardGet.word_for_y(board, 0, 0)
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
    |> Wordza.GameBoard.add_letters([
      %{y: 0, x: 0, letter: Enum.at(abcs, 0), value: 1},
    ])
  end
  defp fill_abcs(board, abcs, y, -1) do
    # nope - too far, move up a row
    count_x = board[0] |> Map.keys() |> Enum.count()
    board
    |> fill_abcs(abcs, y - 1, count_x - 1)
  end
  defp fill_abcs(board, abcs, y, x) do
    board
    |> Wordza.GameBoard.add_letters([
      %{y: y, x: x, letter: Enum.at(abcs, rem((x + y), 26)), value: 1},
    ])
    # next, move left in same row
    |> fill_abcs(abcs, y, x - 1)
  end

  defp board_high_wide() do
    Wordza.GameBoard.create_board(7, 7)
    |> Wordza.GameBoard.add_letters([
      %{y: 1, x: 0, letter: "W", value: 1},
      %{y: 1, x: 1, letter: "I", value: 1},
      %{y: 1, x: 2, letter: "D", value: 1},
      %{y: 1, x: 3, letter: "E", value: 1},
      %{y: 0, x: 1, letter: "H", value: 1},
      %{y: 2, x: 1, letter: "G", value: 1},
      %{y: 3, x: 1, letter: "H", value: 1},
    ])
  end
end
