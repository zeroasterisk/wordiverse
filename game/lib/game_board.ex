defmodule Wordiverse.GameBoard do
  @moduledoc """
  This is our Wordiverse GameBoard
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
  def create(:mock) do
    board = create_board(5, 5)
    board
    |> add_bonus_bulk([[2, 2]], :st)
    |> add_bonus_bulk([[0, 0]], :tw)
    |> add_bonus_bulk([[1, 1]], :dw)
    |> add_bonus_bulk([[0, 2]], :tl)
    |> add_bonus_bulk([[2, 0]], :dl)
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
    {total_y, total_x, center_y, center_x} = measure(board)
    board |> add_bonus_mirror(total_y, center_y, total_x, center_x)
  end
  def add_bonus_mirror(board, _total_y, -1 = _y, _total_x, _x), do: board
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
  Get the basic measurements for a board
  """
  def measure(board) do
    total_y = board |> Map.keys() |> Enum.count()
    total_x = board[0] |> Map.keys() |> Enum.count()
    center_y = Integer.floor_div(total_y, 2)
    center_x = Integer.floor_div(total_x, 2)
    {total_y, total_x, center_y, center_x}
  end

  @doc """
  Convert a board to a 2-dim list matrix of letters
  """
  def to_list(board, key \\ :letter) do
    board
    |> Enum.map(
      fn({_y, row}) ->
        Enum.map(row, fn({_x, cell}) -> Map.get(cell, key, nil) end)
      end
    )
  end

  @doc """
  Is a board empty?
  """
  def empty?(board) do
    board
    |> to_list(:letter)
    |> List.flatten()
    |> Enum.all?(&is_nil/1)
  end

  @doc """

  """
  def get(board, y, x) do
    Map.merge(board[y][x], %{y: y, x: x})
  end

  @doc """
  Get all touching letters for a single y+x
  It will return 2-4 squares from the board, with the y & x added
  """
  def touching(board, y, x) do
    []
    |> touching_left(board, y, x)
    |> touching_bottom(board, y, x)
    |> touching_right(board, y, x)
    |> touching_top(board, y, x)
  end
  def touching_top(acc, _board, 0, _x), do: acc
  def touching_top(acc, board, y, x), do: [get(board, y - 1, x) | acc]
  def touching_right(acc, board, y, x) do
    count_x = board[0] |> Map.keys() |> Enum.count()
    case x > (count_x - 2) do
      true -> acc
      false -> [get(board, y, x + 1) | acc]
    end
  end
  def touching_bottom(acc, board, y, x) do
    count_y = board |> Map.keys() |> Enum.count()
    case y > (count_y - 2) do
      true -> acc
      false -> [get(board, y + 1, x) | acc]
    end
  end
  def touching_left(acc, _board, _y, 0), do: acc
  def touching_left(acc, board, y, x), do: [get(board, y, x - 1) | acc]

end
