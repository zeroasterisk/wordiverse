defmodule Wordza.TourneyGameCore do
  @moduledoc """
  This is the "Autoplayer" part of the TourneyGameWorker

  No GenServer, just simple passthrough functions
  """
  require Logger

  @doc """
  Take as many turns as needed until the game is complete
  """
  def complete(%Wordza.TourneyGameConfig{done: true} = state) do
    {:ok, state}
  end
  def complete(%Wordza.TourneyGameConfig{} = state) do
    state |> next() |> complete()
  end
  def complete({:ok, %Wordza.TourneyGameConfig{} = state}) do
    state |> complete()
  end

  @doc """
  Take the next turn in a game and return state
  or return state with done=true if game is over
  """
  def next(%Wordza.TourneyGameConfig{done: true, game_pid: game_pid} = state) do
    # Logger.warn "TourneyGameCore.next should not have fired, already done, Game##{inspect(game_pid)}"
    {:ok, state}
  end
  def next(%Wordza.TourneyGameConfig{game_pid: game_pid} = state) do
    game = Wordza.Game.get(game_pid, :full)
    play = state |> next_game_play(game)
    case play do
      nil -> {:ok, state |> Map.merge(%{done: true})}
      _ -> {:ok, state}
    end
  end

  @doc """
  This is the actual handler of the next turn, based on game state
  """
  defp next_game_play(
    %Wordza.TourneyGameConfig{game_pid: game_pid} = state,
    %Wordza.GameInstance{turn: :game_over} = game
  ) do
    # Logger.info "TourneyGameCore.next, Game##{inspect(game_pid)} (ENDED)"
    nil
  end
  defp next_game_play(
    %Wordza.TourneyGameConfig{game_pid: game_pid} = state,
    %Wordza.GameInstance{
      turn: turn,
      plays: plays,
    } = game
  ) do
    turn_count = Enum.count(plays)
    # Logger.info "TourneyGameCore.next, Game##{inspect(game_pid)} (turn: #{turn_count}, next: #{turn})"

    player_key = next_get_player_key(turn)
    bot = next_get_bot(turn, state)

    case bot.make_play(player_key, game) do
      {:error, err} -> {:err, err}
      {:pass, nil} ->
        # can not play? add a pass (might end the game)
        Wordza.Game.pass(state.game_pid, player_key)
      {:ok, play} ->
        # apply the play to the game (via the game GenServer)
        player_key = play |> Map.get(:player_key)
        Wordza.Game.play(state.game_pid, player_key, play)
    end
  end

  defp next_get_player_key(1 = _turn), do: :player_1
  defp next_get_player_key(2 = _turn), do: :player_2

  defp next_get_bot(1 = _turn, %Wordza.TourneyGameConfig{player_1_module: bot} = _state), do: bot
  defp next_get_bot(2 = _turn, %Wordza.TourneyGameConfig{player_2_module: bot} = _state), do: bot
end
