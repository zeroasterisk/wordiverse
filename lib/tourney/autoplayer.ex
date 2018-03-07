defmodule Wordza.Autoplayer do
  @moduledoc """
  Auto-Play a Game, run each move, complete the game, then end
  """
  require Logger
  use GenServer

  ### Client API

  @doc """
  Easy access to start up the server

  On new:
    returns {:ok, pid}
  On repeat:
    returns {:error, {:already_started, #PID<0.248.0>}}
  """
  def start_link(game_name_or_pid, module_player1, module_player2) do
    out = GenServer.start_link(__MODULE__, %{
      pid: game_name_or_pid,
      module_player1: module_player1,
      module_player2: module_player2,
    }, [name: __MODULE__])
    out |> start_link_nice()
  end
  def start_link_nice({:ok, pid}), do: {:ok, pid}
  def start_link_nice({:error, {:already_started, pid}}), do: {:ok, pid}
  def start_link_nice({:error, err}), do: {:error, err}

  @doc """
  AutoPlay the next move on a game
  """
  def play_next(pid) do
    GenServer.call(pid, {:play_next, nil})
  end

  @doc """
  AutoPlay a game until it's done (blocking, real time, returns game)
  """
  def play_game(pid) do
    GenServer.call(pid, {:play_game, nil})
  end

  @doc """
  AutoPlay a game until it's done, but do so in the background
  """
  def play_game_background(pid) do
    GenServer.cast(pid, {:play_game, nil})
  end

  ### Server API
  def init(%{
    pid: game_name_or_pid,
    module_player1: module_player1,
    module_player2: module_player2,
  }) do
    {:ok, %{
      pid: game_name_or_pid,
      module_player1: module_player1,
      module_player2: module_player2,
      done: false,
    }}
  end
  def handle_call({:play_next, _}, _from, state) do
    # build new play
    game = Wordza.Game.get(state.pid, :full)
    output = real_play_next(state, game)
    {:reply, output, state}
  end

  def handle_call({:play_game, _}, from, state) do
    # auto-play until done
    game = Wordza.Game.get(state.pid, :full)
    case game.turn do
      :game_over ->
        # we are done, game over... reply as such
        {:reply, {:done, game}, state |> Map.merge(%{done: true})}
      _ ->
        # we are not going to reply... so we basically just re-curse forever
        real_play_next(state, game)
        handle_call({:play_game, nil}, from, state)
    end
  end

  def handle_cast({:play_game, _}, state) do
    # auto-play until done (in background, no reply)
    game = Wordza.Game.get(state.pid, :full)
    case game.turn do
      :game_over ->
        # we are done, game over... reply as such
        {:noreply, state |> Map.merge(%{done: true})}
      _ ->
        # we are not going to reply... so we basically just re-curse forever
        real_play_next(state, game)
        handle_cast({:play_game, nil}, state)
    end
  end


  defp real_play_next(_state, %Wordza.GameInstance{turn: :game_over} = game) do
    {:done, game}
  end
  defp real_play_next(state, %Wordza.GameInstance{} = game) do
    player_key = (game.turn == 2) && :player_2 || :player_1
    # TODO split this out so it could work for either player's module
    case state.module_player2.make_play(player_key, game) do
      {:error, err} -> {:err, err}
      {:pass, nil} ->
        # can not play? add a pass (might end the game)
        Wordza.Game.pass(state.pid, player_key)
      {:ok, play} ->
        # apply the play to the game (via the game GenServer)
        player_key = play |> Map.get(:player_key)
        Wordza.Game.play(state.pid, player_key, play)
    end
  end

end
