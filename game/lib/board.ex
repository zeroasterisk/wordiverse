defmodule Wordiverse.Game.Board do
  @moduledoc """
  This is our Wordiverse Game Board
  The configuration of all board positions.
  The configuration of all current played tiles on the board.

  NOTE I have chosen to represent the board as a map vs. 2 dim list
  because elixir...
  http://blog.danielberkompas.com/2016/04/23/multidimensional-arrays-in-elixir.html
  """

  @doc """
  Build a new board for a type of game
  """
  def create(:scrabble) do
    board = create_board(15, 15)
    board
    |> add_bonus_bulk([
      [7, 7],
    ], :st)
    |> add_bonus_bulk([
      [0, 0],
      [0, 7],
      [0, 14],
      [7, 0],
    ], :tw)
    |> add_bonus_bulk([
      [1, 1],
      [2, 2],
      [3, 3],
      [4, 4],
    ], :dw)
    |> add_bonus_bulk([
      [1, 5],
      [5, 1],
      [5, 5],
    ], :tl)
    |> add_bonus_bulk([
      [0, 3],
      [3, 0],
      [2, 6],
      [6, 2],
      [6, 6],
      [3, 0],
      [3, 7],
      [7, 3],
    ], :dl)
    |> add_bonus_mirror()
  end
  def create(:wordfeud) do
    board = create_board(15, 15)
    board
    |> add_bonus_bulk([
      [7, 7],
    ], :st)
    |> add_bonus_bulk([
      [0, 4],
      [4, 0],
    ], :tw)
    |> add_bonus_bulk([
      [2, 2],
      [4, 4],
      [3, 7],
      [7, 3],
    ], :dw)
    |> add_bonus_bulk([
      [0, 0],
      [1, 5],
      [3, 3],
      [5, 1],
      [5, 5],
    ], :tl)
    |> add_bonus_bulk([
      [0, 7],
      [1, 1],
      [2, 6],
      [4, 6],
      [6, 2],
      [6, 4],
      [7, 0],
    ], :dl)
    |> add_bonus_mirror()
  end

  # given an X & Y count, build out a matrix of nils
  def create_board(y_count, x_count) do
    Range.new(0, x_count - 1)
    |> Enum.reduce(%{}, fn(i, board) -> Map.put(board, i, create_board_row(y_count)) end)
  end
  def create_board_row(y_count) do
    Range.new(0, y_count - 1)
    |> Enum.reduce(%{}, fn(i, row) -> Map.put(row, i, create_board_cell()) end)
  end
  def create_board_cell() do
    %{bonus: nil, letter: nil}
  end

  @doc """
  Update a single cell with a single bonus
  """
  def add_bonus(board, y, x, bonus) do
    put_in(board, [y, x, :bonus], bonus)
  end

  @doc """
  Update a set of cells, with a bonus (bulk add)
  """
  def add_bonus_bulk(board, [] = _coords, _bonus), do: board
  def add_bonus_bulk(board, coords, bonus) do
    {[y, x], coords} = List.pop_at(coords, 0)
    put_in(board, [y, x, :bonus], bonus) |> add_bonus_bulk(coords, bonus)
  end

  @doc """
  Update all bonus cells, make the board a 4 quadrent mirror-copy of the top-left quad
  (this is kinda silly, but fun)
  """
  def add_bonus_mirror(board) do
    total_y = board |> Map.keys() |> Enum.count()
    total_x = board[0] |> Map.keys() |> Enum.count()
    y = Integer.floor_div(total_y, 2)
    x = Integer.floor_div(total_x, 2)
    board |> add_bonus_mirror(total_y, y, total_x, x)
  end
  def add_bonus_mirror(board, total_y, -1 = _y, total_x, _x), do: board
  def add_bonus_mirror(board, total_y, y, total_x, -1 = _x) do
    x = Integer.floor_div(total_x, 2)
    board |> add_bonus_mirror(total_y, y - 1, total_x, x)
  end
  def add_bonus_mirror(board, total_y, y, total_x, x) do
    mirror_at_x = total_x - x - 1
    mirror_at_y = total_y - y - 1
    board
    |> add_bonus(y, mirror_at_x, board[y][x][:bonus])
    |> add_bonus(mirror_at_y, x, board[y][x][:bonus])
    |> add_bonus(mirror_at_y, mirror_at_x, board[y][x][:bonus])
    |> add_bonus_mirror(total_y, y, total_x, x - 1)
  end

  @doc """
  Convert a board to a 2-dim list matrix of letters
  """
  def to_list(board, key \\ :letter) do
    board
    |> Map.values()
    |> Enum.map(
      fn(row) ->
        row |> Map.values() |> Enum.map(
          fn(cell) -> Map.get(cell, key, nil) end
        )
      end
    )
  end

end
