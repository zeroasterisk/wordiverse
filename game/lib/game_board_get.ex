defmodule Wordiverse.GameBoardGet do
  @moduledoc """
  This is our Wordiverse GameBoard getter
  it looks up various values from a board

  Some of the main methods are
  - at (a single y+x)
  - touching (a single y+x)
  - words (for all played letters_yx)
  """
  require Logger

  @doc """
  Get the square details from a board, for a single y + x
  (note, we are merging the board square, with the y + x for easy usage)

  ## Examples

      iex> board = %{0 => %{0 => %{letter: nil}, 1 => %{letter: "A"}}}
      iex> Wordiverse.GameBoardGet.at(board, 0, 1)
      %{letter: "A", y: 0, x: 1}
  """
  def at(board, y, x) do
    Map.merge(board[y][x], %{y: y, x: x})
  end

  @doc """
  Get all touching letters for a single y+x
  It will return 2-4 squares from the board, with the y & x added

  ## Examples

      iex> board = Wordiverse.GameBoard.create_board(3, 3)
      iex> Wordiverse.GameBoardGet.touching(board, 0, 0)
      [
        %{bonus: nil, letter: nil, x: 1, y: 0},
        %{bonus: nil, letter: nil, x: 0, y: 1},
      ]
  """
  def touching(board, y, x) do
    []
    |> touching_left(board, y, x)
    |> touching_bottom(board, y, x)
    |> touching_right(board, y, x)
    |> touching_top(board, y, x)
  end
  defp touching_top(acc, _board, 0, _x), do: acc
  defp touching_top(acc, board, y, x), do: [at(board, y - 1, x) | acc]
  defp touching_right(acc, board, y, x) do
    count_x = board[0] |> Map.keys() |> Enum.count()
    case x > (count_x - 2) do
      true -> acc
      false -> [at(board, y, x + 1) | acc]
    end
  end
  defp touching_bottom(acc, board, y, x) do
    count_y = board |> Map.keys() |> Enum.count()
    case y > (count_y - 2) do
      true -> acc
      false -> [at(board, y + 1, x) | acc]
    end
  end
  defp touching_left(acc, _board, _y, 0), do: acc
  defp touching_left(acc, board, y, x), do: [at(board, y, x - 1) | acc]

  @doc """
  Get all touching "words", given a list of x & y letters
  we will expand to find all words in a column and/or row
  """
  def touching_words(board, letters_yx) do
    # for each letter
    #   find all touching words in row
    #   find all touching words in column
    words_y = letters_yx |> Enum.map(fn([letter, y, x]) -> word_for_y(board, y, x) end)
    words_x = letters_yx |> Enum.map(fn([letter, y, x]) -> word_for_x(board, y, x) end)
    words_y ++ words_x |> Enum.uniq() |> Enum.filter(fn(word) -> Enum.count(word) > 1 end)
  end
  def get_words_for_letter(%{board: board, words: words, scanned: scanned} = proc, y, x, letter) do
    case Enum.member?(scanned, [y, x]) do
      true ->
        Logger.info "sanned #{x}, #{y}"
        proc
      false ->
        word_y = word_for_y(board, y, x)
        Map.merge(proc, %{
          words: [word_y | words],
        })
    end
  end
  def word_for_y(board, y, x) do
    square = at(board, y, x)
    [square]
    |> word_for_y_up(board, (y - 1), x)
    |> word_for_y_down(board, (y + 1), x)
    |> Enum.sort(fn(%{y: y1}, %{y: y2}) -> y1 < y2 end)
  end
  defp word_for_y_up(word_part, _board, -1, _x), do: word_part
  defp word_for_y_up(word_part, board, y, x) do
    square = at(board, y, x)
    case Map.get(square, :letter) do
      nil -> word_part
      _ ->
        [square | word_part]
        |> word_for_y_up(board, (y - 1), x)
    end
  end
  defp word_for_y_down(word_part, board, y, x) do
    count_y = board |> Map.keys() |> Enum.count()
    case y > (count_y - 2) do
      true -> word_part
      false ->
        square = at(board, y, x)
        case Map.get(square, :letter) do
          nil -> word_part
          _ ->
            [square | word_part]
            |> word_for_y_down(board, (y + 1), x)
        end
    end
  end
  def word_for_x(board, y, x) do
    square = at(board, y, x)
    [square]
    |> word_for_x_left(board, y, (x - 1))
    |> word_for_x_right(board, y, (x + 1))
    |> Enum.sort(fn(%{x: x1}, %{x: x2}) -> x1 < x2 end)
  end
  defp word_for_x_left(word_part, _board, _y, -1), do: word_part
  defp word_for_x_left(word_part, board, y, x) do
    square = at(board, y, x)
    case Map.get(square, :letter) do
      nil -> word_part
      _ ->
        [square | word_part]
        |> word_for_x_left(board, y, (x - 1))
    end
  end
  defp word_for_x_right(word_part, board, y, x) do
    count_x = board[0] |> Map.keys() |> Enum.count()
    case x > (count_x - 2) do
      true -> word_part
      false ->
        square = at(board, y, x)
        case Map.get(square, :letter) do
          nil -> word_part
          _ ->
            [square | word_part]
            |> word_for_x_right(board, y, (x + 1))
        end
    end
  end

end
