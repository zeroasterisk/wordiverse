defmodule Wordiverse.Game do
  @moduledoc """
  This is our Wordiverse Game, a single game managing:
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

  defstruct [
    type: nil,
    board: nil,
    tiles_in_pile: nil,
    player_1: nil,
    player_2: nil,
    turn: 1,
    score: 0,
    plays: [],
  ]

  ### Client API
  @doc """
  Easy access to start up the server

  On new:
    returns {:ok, pid}
  On repeat:
    returns {:error, {:already_started, #PID<0.248.0>}}
  """
  def start_link(type, player_1_id, player_2_id) do
    GenServer.start_link(
      __MODULE__,
      [type, player_1_id, player_2_id],
      [
        name: type,
        timeout: 30_000, # 30 seconds to init or die
      ]
    )
  end
  def get(pid, key \\ :board) do
    GenServer.call(pid, {:get, key})
  end

  ### Server API

  @doc """

  """
  def init([type, player_1_id, player_2_id]) do
    allowed = [:scrabble, :wordfeud, :mock]
    case Enum.member?(allowed, type) do
      true -> {:ok, Wordiverse.GameActions.create(type, player_1_id, player_2_id)}
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



end
