defmodule GameBoardTest do
  use ExUnit.Case
  doctest Wordiverse.Game.Board

  test "create board for scrabble" do
    board = Wordiverse.Game.Board.create(:scrabble)
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
    bonus_matrix = board |> Wordiverse.Game.Board.to_list(:bonus)
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
    board = Wordiverse.Game.Board.create(:wordfeud)
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
    bonus_matrix = board |> Wordiverse.Game.Board.to_list(:bonus)
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
    assert Wordiverse.Game.Board.create_board_row(4) == %{
      0 => %{bonus: nil, letter: nil},
      1 => %{bonus: nil, letter: nil},
      2 => %{bonus: nil, letter: nil},
      3 => %{bonus: nil, letter: nil},
    }
  end
  test "create board for a given length of columns and rows" do
    assert Wordiverse.Game.Board.create_board(2, 2) == %{
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

end