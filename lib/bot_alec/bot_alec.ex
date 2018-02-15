defmodule Wordza.BotAlec do
  @moduledoc """
  Beep Beep, a Bot for Wordza: Look at all possible plays and pick highest scoring

  This guy is really good - but has no strategy - purely picking the best word formable right now.

  Scenario: "Build a play with BotAlec"

      Given a GamePlayer and a GameInstance
      When we choose a play to make
      Then return a GamePlay which is both valid and the highest scoring
  """
  require Logger
  alias Wordza.BotAlec
  alias Wordza.BotBits
  alias Wordza.GameInstance
  alias Wordza.GamePlayer
  # alias Wordza.GamePlay
  alias Wordza.GameBoard
  alias Wordza.BotPlayMaker

  defstruct [
    player_key: :player_1,
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
  def play(
    player_key,
    %GameInstance{
      board: board,
      type: type,
    } = game
  ) when is_atom(player_key) do
    player = game |> Map.get(player_key)
    tiles_in_tray = player |> Map.get(:tiles_in_tray)
    {total_y, total_x, center_y, center_x} = board |> GameBoard.measure

    %BotAlec{
      player_key: player_key,
      tiles_in_tray: tiles_in_tray,
      type: type,
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
  defp assign_word_starts(%BotAlec{type: type, tiles_in_tray: tiles_in_tray} = bot) do
    bot |> Map.merge(%{word_starts: BotBits.get_all_word_starts(tiles_in_tray, type)})
  end
  defp assign_all_plays(%BotAlec{} = bot, %GameInstance{} = game) do
    bot |> Map.merge(%{plays: BotPlayMaker.create_all_plays(game, bot)})
  end
  defp choose_play(%BotAlec{plays: plays} = _bot) do
    plays
    # all of this should be done already by BotPlayMaker.create_all_plays
    # |> Enum.filter(fn(%{valid: v}) -> v == true end)
    # now sort by score (why not?) [decsending]
    # |> Enum.sort(fn(%{score: s1}, %{score: s2}) -> s1 > s2 end)
    |> List.first()
  end


  # debug some possible plays
  defp debug_show_all_plays(%{plays: plays} = bot) do
    plays |> Enum.each(fn(%{board_next: board_next, score: score}) ->
      IO.puts ""
      IO.puts "option: score = #{score}"
      IO.puts GameBoard.to_string(board_next)
    end)

    bot
  end

end

