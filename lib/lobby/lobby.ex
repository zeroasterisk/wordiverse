defmodule Wordza.Lobby do
  @moduledoc """
  A Lobby hasMany Games (each is a GenServer running a single GameInstance)

  This is our Wordza Lobby, the "state" where all running games live

  We only need 1 Lobby, which contains the list of all running Games

  When we create a GameInstance, we will run that inside a Game (server)
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
  def start_link() do
    out = GenServer.start_link(__MODULE__, nil, [name: __MODULE__])
    out |> start_link_nice()
  end
  def start_link_nice({:ok, pid}), do: {:ok, pid}
  def start_link_nice({:error, {:already_started, pid}}), do: {:ok, pid}
  def start_link_nice({:error, err}), do: {:error, err}

  @doc """
  Create a Game, only works with both users
  """
  def create_game(type, player_1_id, player_2_id) do
    GenServer.call(__MODULE__, {:create_game, type, player_1_id, player_2_id})
  end

  @doc """
  List currently running games (filterable with keys: pid, type, player_1_id, player_2_id)
  """
  def list_games(%{} = filter) do
    GenServer.call(__MODULE__, {:list_games, filter})
  end
  def list_games() do
    GenServer.call(__MODULE__, {:list_games, %{}})
  end

  @doc """
  End a currently running game
  """
  def end_game(pid_or_name) do
    GenServer.call(__MODULE__, {:end_game, pid_or_name})
  end

  @doc """
  Remove a game from the state (it should have already been ended)
  """
  def remove_game(pid_or_name) do
    GenServer.call(__MODULE__, {:remove_game, pid_or_name})
  end

  @doc """
  Get a game from the state

  Returns the full GameInstance
  """
  def get_game_pid(pid_or_name) do
    GenServer.call(__MODULE__, {:get_game_pid, pid_or_name})
  end


  ### Server API
  def init(_initial_state) do
    {:ok, %{}}
  end
  def handle_call({:create_game, type, player_1_id, player_2_id}, _from, state) do
    # Build a game name for this Game
    name = Wordza.GameInstance.build_game_name(type)
    case Wordza.Game.start_link(type, player_1_id, player_2_id, name) do
      {:ok, pid} ->
        # If the Game dies, we want to know about it (see handle_info for capture)
        Process.monitor(pid)
        # gather the "state" for this game, we want to track here (ghetto lobby)
        game = %{pid: pid, name: name, type: type, player_1_id: player_1_id, player_2_id: player_2_id}
        # return a new state, storing the information about this game
        {:reply, {:ok, name}, state |> Map.merge(%{name => game})}
      {:error, err} ->
        Logger.error fn() -> "Unable to create_game (from Lobby): #{inspect(err)}" end
        {:reply, {:error, err}, state}
    end
  end

  def handle_call({:list_games, %{} = filter}, _from, state) do
    {:reply, {:ok, state |> Enum.filter(fn(game) -> filterer(game, filter) end)}, state}
  end

  def handle_call({:end_game, pid_or_name}, _from, state) do
    # we can just kill that Game... we will catch that and remove it below in handle_info()
    pid = get_pid(pid_or_name, state)
    {:reply, {:ok, Process.exit(pid, :normal)}, state}
  end

  def handle_call({:remove_game, pid}, from, state) when is_pid(pid) do
    name = get_name(pid, state)
    handle_call({:remove_game, name}, from, state)
  end
  def handle_call({:remove_game, name}, _from, state) when is_bitstring(name) do
    {:reply, {:ok, :removed}, state |> Map.delete(name)}
  end
  def handle_call({:get_game_pid, pid_or_name}, _from, state) do
    {:reply, {:ok, get_pid(pid_or_name, state)}, state}
  end


  def handle_info({:DOWN, _, :process, pid, exit_code}, from, state) do
    # When a monitored process dies, we will receive a `:DOWN` message
    # that we can use to remove the dead pid from our registry
    Logger.info fn() -> "alerted on the end of a Game #{inspect(pid)} as #{inspect(exit_code)}" end
    # TODO can we capture the state of the game somewhere?
    {:noreply, handle_call({:remove_game, pid}, from, state)}
  end

  # helpers to get name or pid from state
  def get_pid(pid_or_name, state) when is_pid(pid_or_name), do: pid_or_name
  def get_pid(pid_or_name, state) when is_bitstring(pid_or_name) do
    state |> Map.get(pid_or_name) |> Map.get(:pid)
  end
  def get_name(pid, state) when is_pid(pid) do
    names = state
            |> Enum.filter(fn({name, %{pid: p}}) -> p == pid end)
            |> Enum.map(fn({name, game}) -> name end)
    case min(2, Enum.count(names)) do
      1 -> names |> List.first()
      2 -> raise "Lobby unable to get_name for #{inspect(pid)} - too many matches"
      0 -> raise "Lobby unable to get_name for #{inspect(pid)} - no matches"
    end
  end

  @doc """
  A custom filtering component, helping filter the list to match any specified paramaters

  TODO review - this is a fun recursion pattern, but feels clunky - I bet this is already implemented better somewhere else.

  ## Examples

      iex> Wordza.Lobby.filterer(%{}, %{})
      true

      iex> Wordza.Lobby.filterer(%{type: :x}, %{type: :x})
      true

      iex> Wordza.Lobby.filterer(%{type: :x}, %{type: :y})
      false
  """
  def filterer(game, %{type: type} = filter) do
    case Map.get(game, :type) == type || is_nil(type) do
      true -> filterer(game, filter |> Map.delete(:type))
      false -> false
    end
  end
  def filterer(game, %{player_1_id: player_1_id} = filter) do
    case Map.get(game, :player_1_id) == player_1_id || is_nil(player_1_id) do
      true -> filterer(game, filter |> Map.delete(:player_1_id))
      false -> false
    end
  end
  def filterer(game, %{player_2_id: player_2_id} = filter) do
    case Map.get(game, :player_2_id) == player_2_id || is_nil(player_2_id) do
      true -> filterer(game, filter |> Map.delete(:player_2_id))
      false -> false
    end
  end
  def filterer(game, %{}), do: true

end
