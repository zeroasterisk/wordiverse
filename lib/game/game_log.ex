defmodule Wordza.GameLog do
  @moduledoc """
  Log a game
  - single line for stdout
  - mongodb or some other db
  - file.io or some other db
  """
  require Logger
  use GenServer

  @default_conf %{
    log_style: :stdout,
  }

  ### Client API

  @doc """
  write a complete game to the logger
  """
  def write(%Wordza.GameInstance{} = game, %{log_style: :stdout} = conf \\ @default_conf) do
    Logger.info game_to_str(game)
    :ok
  end
  def write(%Wordza.GameInstance{} = game, %{} = _bad_conf) do
    # Logger.warn "GameLog.write with invalid/missing log_style #{inspect(bad_conf)}"
    Wordza.GameLog.write(game)
  end

  def game_to_str(%Wordza.GameInstance{
    name: name,
    player_1: player_1,
    player_2: player_2,
    plays: plays,
    board: board,
  } = game) do
    last_play = plays |> List.last()
    score_1 = player_1.score |> nice_score
    score_2 = player_2.score |> nice_score
    [
      "GAME",
      name |> String.pad_trailing(32, " "),
      "score: #{score_1} vs. #{score_2}",
      "num_plays: #{Enum.count(plays)}",
      "last_play: #{last_play |> play_to_str}",
    ]
    |> Enum.join(" ")
  end
  def play_to_str(%Wordza.GamePlay{
    words: words,
    player_key: player_key,
    score: score,
  } = game) do
    [
      player_key,
      "scored: #{score} with:",
      Wordza.GamePlay.simplify_words(words)
    ]
    |> Enum.join(" ")
  end
  def nice_score(score) do
    score
    |> Integer.to_string()
    |> String.pad_leading(3, " ")
  end

end
