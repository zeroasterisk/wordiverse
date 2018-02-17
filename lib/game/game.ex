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


  ### Client API
  @doc """
  Easy access to start up the server

  On new:
    returns {:ok, pid}
  On repeat:
    returns {:error, {:already_started, #PID<0.248.0>}}
  """
  def start_link(type, player_1_id, player_2_id) do
    name = Wordza.GameInstance.build_game_name(type)
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
  def get(pid_or_name, key \\ :board)
  def get(pid, key) when is_pid(pid), do: pid |> GenServer.call({:get, key})
  def get(name, key), do: name |> via_tuple |> GenServer.call({:get, key})
  def board(pid_or_name), do: get(pid_or_name, :board)
  def player_1(pid_or_name), do: get(pid_or_name, :player_1)
  def player_2(pid_or_name), do: get(pid_or_name, :player_2)
  def tiles(pid_or_name), do: get(pid_or_name, :tiles)

  ### Server API

  @doc """

  """
  def init([type, player_1_id, player_2_id, name]) do
    allowed = [:scrabble, :wordfeud, :mock]
    case Enum.member?(allowed, type) do
      true -> {:ok, Wordza.GameInstance.create(type, player_1_id, player_2_id, name)}
      false -> {:error, "Invalid type supplied to Game init #{type}"}
    end
  end
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

  # Fancy name <-> pid refernce library `gproc`
  defp via_tuple(name) do
    {:via, :gproc, {:n, :l, {:wordza_game, name}}}
  end

end
