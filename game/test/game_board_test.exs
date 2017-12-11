defmodule GameBoardTest do
  use ExUnit.Case
  doctest Wordiverse.GameBoard

  test "create board for scrabble" do
    board = Wordiverse.GameBoard.create(:scrabble)
    assert board |> Map.keys() |> Enum.count() == 15
    assert board[0] |> Map.keys() |> Enum.count() == 15
    assert board[0][0] == %{
      bonus: :tw,
      letter: nil,
    }
    assert board[0][1] == %{
      bonus: nil,
      letter: nil,
    }
    assert board[0][3] == %{
      bonus: :dl,
      letter: nil,
    }
    assert board[0][14] == %{
      bonus: :tw,
      letter: nil,
    }
    bonus_matrix = board |> Wordiverse.GameBoard.to_list(:bonus)
    assert bonus_matrix == [
      [:tw, nil, nil, :dl, nil, nil, nil, :tw, nil, nil, nil, :dl, nil, nil, :tw],
      [nil, :dw, nil, nil, nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :dw, nil],
      [nil, nil, :dw, nil, nil, nil, :dl, nil, :dl, nil, nil, nil, :dw, nil, nil],
      [:dl, nil, nil, :dw, nil, nil, nil, :dl, nil, nil, nil, :dw, nil, nil, :dl],
      [nil, nil, nil, nil, :dw, nil, nil, nil, nil, nil, :dw, nil, nil, nil, nil],
      [nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil],
      [nil, nil, :dl, nil, nil, nil, :dl, nil, :dl, nil, nil, nil, :dl, nil, nil],
      [:tw, nil, nil, :dl, nil, nil, nil, :st, nil, nil, nil, :dl, nil, nil, :tw],
      [nil, nil, :dl, nil, nil, nil, :dl, nil, :dl, nil, nil, nil, :dl, nil, nil],
      [nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil],
      [nil, nil, nil, nil, :dw, nil, nil, nil, nil, nil, :dw, nil, nil, nil, nil],
      [:dl, nil, nil, :dw, nil, nil, nil, :dl, nil, nil, nil, :dw, nil, nil, :dl],
      [nil, nil, :dw, nil, nil, nil, :dl, nil, :dl, nil, nil, nil, :dw, nil, nil],
      [nil, :dw, nil, nil, nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :dw, nil],
      [:tw, nil, nil, :dl, nil, nil, nil, :tw, nil, nil, nil, :dl, nil, nil, :tw],
    ]
  end
  test "create board for wordfeud" do
    board = Wordiverse.GameBoard.create(:wordfeud)
    assert board |> Map.keys() |> Enum.count() == 15
    assert board[0] |> Map.keys() |> Enum.count() == 15
    assert board[0][0] == %{
      bonus: :tl,
      letter: nil,
    }
    assert board[0][1] == %{
      bonus: nil,
      letter: nil,
    }
    assert board[1][1] == %{
      bonus: :dl,
      letter: nil,
    }
    assert board[0][14] == %{
      bonus: :tl,
      letter: nil,
    }
    bonus_matrix = board |> Wordiverse.GameBoard.to_list(:bonus)
    assert bonus_matrix == [
      [:tl, nil, nil, nil, :tw, nil, nil, :dl, nil, nil, :tw, nil, nil, nil, :tl],
      [nil, :dl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :dl, nil],
      [nil, nil, :dw, nil, nil, nil, :dl, nil, :dl, nil, nil, nil, :dw, nil, nil],
      [nil, nil, nil, :tl, nil, nil, nil, :dw, nil, nil, nil, :tl, nil, nil, nil],
      [:tw, nil, nil, nil, :dw, nil, :dl, nil, :dl, nil, :dw, nil, nil, nil, :tw],
      [nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil],
      [nil, nil, :dl, nil, :dl, nil, nil, nil, nil, nil, :dl, nil, :dl, nil, nil],
      [:dl, nil, nil, :dw, nil, nil, nil, :st, nil, nil, nil, :dw, nil, nil, :dl],
      [nil, nil, :dl, nil, :dl, nil, nil, nil, nil, nil, :dl, nil, :dl, nil, nil],
      [nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil],
      [:tw, nil, nil, nil, :dw, nil, :dl, nil, :dl, nil, :dw, nil, nil, nil, :tw],
      [nil, nil, nil, :tl, nil, nil, nil, :dw, nil, nil, nil, :tl, nil, nil, nil],
      [nil, nil, :dw, nil, nil, nil, :dl, nil, :dl, nil, nil, nil, :dw, nil, nil],
      [nil, :dl, nil, nil, nil, :tl, nil, nil, nil, :tl, nil, nil, nil, :dl, nil],
      [:tl, nil, nil, nil, :tw, nil, nil, :dl, nil, nil, :tw, nil, nil, nil, :tl],
    ]
  end
  test "create board row for a given length of columns" do
    assert Wordiverse.GameBoard.create_board_row(4) == %{
      0 => %{bonus: nil, letter: nil},
      1 => %{bonus: nil, letter: nil},
      2 => %{bonus: nil, letter: nil},
      3 => %{bonus: nil, letter: nil},
    }
  end
  test "create board for a given length of columns and rows" do
    assert Wordiverse.GameBoard.create_board(2, 2) == %{
      0 => %{
        0 => %{bonus: nil, letter: nil},
        1 => %{bonus: nil, letter: nil},
      },
      1 => %{
        0 => %{bonus: nil, letter: nil},
        1 => %{bonus: nil, letter: nil},
      }
    }
  end
  test "empty? should determine if any letter is anywhere on the board" do
    board = Wordiverse.GameBoard.create_board(2, 2)
    assert Wordiverse.GameBoard.empty?(board) == true
    board = put_in(board, [0, 0, :letter], "a")
    assert Wordiverse.GameBoard.empty?(board) == false

    board = Wordiverse.GameBoard.create_board(15, 15)
    assert Wordiverse.GameBoard.empty?(board) == true
    board = put_in(board, [12, 12, :letter], "a")
    assert Wordiverse.GameBoard.empty?(board) == false
  end
  test "touching should return adjacent squares for all 4 directions if not edge" do
    board = Wordiverse.GameBoard.create_board(15, 15) |> fill_abcs()
    assert Wordiverse.GameBoard.touching(board, 5, 5) == [
      %{bonus: nil, letter: "J", y: 4, x: 5}, # top (y-1)
      %{bonus: nil, letter: "L", y: 5, x: 6}, # right (x+1)
      %{bonus: nil, letter: "L", y: 6, x: 5}, # bottom (y+1)
      %{bonus: nil, letter: "J", y: 5, x: 4}, # left (x-1)
    ]
  end
  test "touching should return adjacent squares for only 3 directions if edge" do
    board = Wordiverse.GameBoard.create_board(15, 15) |> fill_abcs()
    assert Wordiverse.GameBoard.touching(board, 0, 0) == [
      %{bonus: nil, letter: "B", y: 0, x: 1}, # right (x+1)
      %{bonus: nil, letter: "B", y: 1, x: 0}, # bottom (y+1)
    ]
    assert Wordiverse.GameBoard.touching(board, 0, 7) == [
      %{bonus: nil, letter: "I", y: 0, x: 8},
      %{bonus: nil, letter: "I", y: 1, x: 7},
      %{bonus: nil, letter: "G", y: 0, x: 6},
    ]
    assert Wordiverse.GameBoard.touching(board, 14, 7) == [
      %{bonus: nil, letter: "U", y: 13, x: 7},
      %{bonus: nil, letter: "W", y: 14, x: 8},
      %{bonus: nil, letter: "U", y: 14, x: 6},
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

end
