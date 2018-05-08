defmodule Wordza.BotAlec do
  @moduledoc """
  Beep Beep, a Bot for Wordza: Look at all possible plays and pick highest scoring

  This guy is really good - but has no strategy - purely picking the best word formable right now.

  Scenario: "Build a play with BotAlec"

      Given a GamePlayer and a GameInstance
      When we choose a play to make
      Then return a GamePlay which is both valid and the highest scoring
  """
  use Elixometer
  require Logger
  alias Wordza.BotAlec
  alias Wordza.BotBits
  alias Wordza.GameInstance
  # alias Wordza.GamePlayer
  # alias Wordza.GamePlay
  alias Wordza.GameBoard
  alias Wordza.BotPlayMaker

  defstruct [
    player_key: :player_1,
    dictionary_name: nil,
    type: nil,
    tiles_in_tray: nil,
    word_starts: [],
    start_yxs: [],
    plays: [],
    board: nil,
    total_y: nil,
    total_x: nil,
    center_y: nil,
    center_x: nil,
    first_play?: false,
    valid_plays: [],
    # keep track of garbage, so we don't attempt it anymore
    invalid_starts: [],
    invalid_words: [],
    errors: [],
  ]


  @doc """
  Make a legal play, before timeout

  TODO build out an Task.await or genserver
  to attmpt multiple variations and maintain state across them

  TODO allow preference to resolve ties (?)

  TODO <-- get from GameInstance
  """
  @timed(key: :auto)
  def make_play(
    player_key,
    %GameInstance{
      board: board,
      type: type,
      dictionary_name: dictionary_name,
    } = game
  ) when is_atom(player_key) do
    player = game |> Map.get(player_key)
    tiles_in_tray = player |> Map.get(:tiles_in_tray)
    {total_y, total_x, center_y, center_x} = board |> GameBoard.measure

    %BotAlec{
      player_key: player_key,
      tiles_in_tray: tiles_in_tray,
      type: type,
      dictionary_name: dictionary_name,
      board: board,
      total_y: total_y,
      total_x: total_x,
      center_y: center_y,
      center_x: center_x,
      first_play?: GameBoard.empty?(board),
    }
    |> assign_start_yxs()
    |> assign_word_starts()
    |> assign_all_plays(game)
    # |> debug_show_all_plays()
    |> choose_play()
  end

  defp assign_start_yxs(%BotAlec{first_play?: true, board: board, tiles_in_tray: tiles_in_tray} = bot) do
    bot |> Map.merge(%{start_yxs: BotBits.get_all_start_yx_first_play(board, tiles_in_tray)})
  end
  defp assign_start_yxs(%BotAlec{board: board, tiles_in_tray: tiles_in_tray} = bot) do
    bot |> Map.merge(%{start_yxs: BotBits.get_all_start_yx(board, tiles_in_tray)})
  end
  defp assign_word_starts(%BotAlec{
    dictionary_name: dictionary_name,
    tiles_in_tray: tiles_in_tray
  } = bot) do
    bot |> Map.merge(%{word_starts: BotBits.get_all_word_starts(tiles_in_tray, dictionary_name)})
  end
  defp assign_all_plays(%BotAlec{} = bot, %GameInstance{} = game) do
    bot |> Map.merge(%{
      plays: BotPlayMaker.create_all_plays(game, bot),
    })
  end
  defp choose_play(%BotAlec{plays: []} = _bot) do
    {:pass, nil}
  end
  defp choose_play(%BotAlec{plays: plays} = _bot) when is_list(plays) do
    play = plays
          # all of this should be done already by BotPlayMaker.create_all_plays
          |> Enum.filter(fn(%{valid: v}) -> v == true end)
          # pre-sort by tiles_in_play (mostly just for consistancy)
          # now sort by score
          #   score (most important) that's the point [descending]
          #   tiles_in_play (we want a deterministic consistancy for testing)
          |> Enum.sort(fn(%{
            score: s1,
            tiles_in_play: x1
          },
          %{
            score: s2,
            tiles_in_play: x2
          }) -> score_sort(s1, x1) > score_sort(s2, x2) end)
          # we only want the first
          |> List.first()
    {:ok, play}
  end
  # we want to convert tiles_in_play to a numeric value for deterministic sorting
  defp score_sort(score, tiles_in_play) do
    letter_count = tiles_in_play |> Enum.count()
    letters = tiles_in_play
              |> Enum.map(fn(%{letter: l}) -> l end)
              |> Enum.join()
    letter_sum = letters
                 |> String.to_charlist()
                 |> Enum.sum()
    x_sum = tiles_in_play
            |> Enum.map(fn(%{x: x}) -> x end)
            |> Enum.sum()
    y_sum = tiles_in_play
            |> Enum.map(fn(%{y: y}) -> y end)
            |> Enum.sum()
    [
      # score is the most important, always
      (score * 1_000_000_000),
      # number of letters is next most important
      (letter_count * 1_000_000),
      # then some junk to ensure we are always sorting the same
      (letter_sum * 1_000),
      (x_sum * 10),
      (y_sum),
    ] |> Enum.sum()
  end


  # debug some possible plays
  # defp debug_show_all_plays(%{plays: plays} = bot) do
  #   plays |> Enum.each(fn(%{board_next: board_next, score: score}) ->
  #     IO.puts ""
  #     IO.puts "option: score = #{score}"
  #     IO.puts GameBoard.to_string(board_next)
  #   end)
  #
  #   bot
  # end

end

