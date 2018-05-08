defmodule Wordza.Game do
  @moduledoc """
  This is our Wordza Game, a single game managing:
  - Config (dictionary, rules)
  - Tiles (tiles available)
  - Board (tiles tiles played)
  - Players (tiles in trays, current score)
  - Plays (history, game log)
  - Scores

  We are going to base it largely off of WordFued and Scabble

  With minor changes to the board configuration, dictionary, and rules
  it should be compatible with either...

  Therefore the create_game and dictionary and rules are all
  keyed into game_type.
  """
  use GenServer
  alias Wordza.GameInstance
  alias Wordza.GamePlay

  ### Client API
  @doc """
  Easy access to start up the server

  On new:
    returns {:ok, pid}
  On repeat:
    returns {:error, {:already_started, #PID<0.248.0>}}
  """
  def start_link(type, player_1_id, player_2_id) do
    name = GameInstance.build_game_name(type)
    start_link(type, player_1_id, player_2_id, name)
  end
  def start_link(type, player_1_id, player_2_id, name) do
    GenServer.start_link(
      __MODULE__,
      [type, player_1_id, player_2_id, name],
      [
        timeout: 30_000, # 30 seconds to init or die
        name: via_tuple(name), # named game (optionally eaiser to lookup)
      ]
    )
  end

  @doc """
  get information about this game
  try get(pid, :full) for everything
  """
  def get(pid_or_name, key \\ :board)
  def get(pid, key) when is_pid(pid), do: pid |> GenServer.call({:get, key})
  def get(name, key), do: name |> via_tuple |> GenServer.call({:get, key})
  def board(pid_or_name), do: get(pid_or_name, :board)
  def player_1(pid_or_name), do: get(pid_or_name, :player_1)
  def player_2(pid_or_name), do: get(pid_or_name, :player_2)
  def tiles(pid_or_name), do: get(pid_or_name, :tiles)
  def turn(pid_or_name), do: get(pid_or_name, :turn)
  def game_over?(pid_or_name), do: get(pid_or_name, :turn) == :game_over

  @doc """
  submit a play for this game (from a UI)
  already have a GamePlay (bot generated?) - you can submit it
  """
  def play(pid_or_name, player_key, %GamePlay{} = play) do
    pid_or_name |> GenServer.call({:play, player_key, play})
  end
  def play(pid_or_name, player_key, letters_yx) do
    pid_or_name |> GenServer.call({:play, player_key, letters_yx})
  end

  @doc """
  submit a pass for this game (from a UI)
  """
  def pass(pid_or_name, player_key) do
    pid_or_name |> GenServer.call({:pass, player_key})
  end

  ### Server API

  @doc """

  """
  def init([type, player_1_id, player_2_id, name]) do
    allowed = [:scrabble, :wordfeud, :mock]
    case Enum.member?(allowed, type) do
      true -> {:ok, GameInstance.create(type, player_1_id, player_2_id, name)}
      false -> {:error, "Invalid type supplied to Game init #{type}"}
    end
  end
  # NOTE state = game
  #   (that's the point, GenServer Game.state = "game state")
  def handle_call({:get, :full}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:get, :player_1}, _from, state) do
    {:reply, Map.get(state, :player_1), state}
  end
  def handle_call({:get, :player_2}, _from, state) do
    {:reply, Map.get(state, :player_2), state}
  end
  def handle_call({:get, :board}, _from, state) do
    {:reply, Map.get(state, :board), state}
  end
  def handle_call({:get, :tiles}, _from, state) do
    {:reply, Map.get(state, :tiles_in_pile), state}
  end
  def handle_call({:get, :turn}, _from, state) do
    {:reply, Map.get(state, :turn), state}
  end
  def handle_call({:play, _player_key, %GamePlay{} = play}, _from, state) do
    case GameInstance.apply_play(state, play) do
      {:ok, state} -> {:reply, {:ok, state}, state}
      {:error, err} -> {:reply, {:error, err}, state}
    end
  end
  def handle_call({:play, player_key, letters_yx}, from, state) do
    play = player_key |> GamePlay.create(letters_yx) |> GamePlay.verify(state)
    handle_call({:play, player_key, play}, from, state)
  end
  def handle_call({:pass, player_key}, _from, state) do
    case GameInstance.apply_pass(state, player_key) do
      {:ok, state} -> {:reply, {:ok, state}, state}
      {:error, err} -> {:reply, {:error, err}, state}
    end
  end

  # Fancy name <-> pid refernce library `gproc`
  defp via_tuple(pid) when is_pid(pid), do: pid
  defp via_tuple(name) when is_atom(name), do: name
  defp via_tuple(name) do
    {:via, :gproc, {:n, :l, {:wordza_game, name}}}
  end

end
