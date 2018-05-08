defmodule Wordza.Dictionary do
  @moduledoc """
  This is our Wordza.Dictionary
  We only need 1 dictionary, for all of our Games of each type
  So it is it's own GenServer
  """
  import Cachex.Spec
  use Elixometer
  use GenServer

  ### Client API

  @doc """
  Easy access to start up the server

  ## Examples

      iex> {:ok, pid} = Wordza.Dictionary.start_link(:mock)
      iex> is_pid(pid)
      true

      iex> {:ok, pid} = Wordza.Dictionary.start_link(:mock, :custom_name)
      iex> is_pid(pid)
      true

      iex> {:ok, pid} = Wordza.Dictionary.start_link({:clone, :mock}, :custom_name)
      iex> is_pid(pid)
      true


  returns {:ok, pid}
  """
  def start_link(type), do: start_link(type, type)
  def start_link({:clone, type}, name) do
    GenServer.start_link(__MODULE__, {:clone, type}, [
      timeout: 30_000, # 30 seconds to init or die
      name: via_tuple(name), # named dictionary (optionally eaiser to lookup)
    ])
    |> start_link_nice()
  end
  def start_link(type, name) do
    GenServer.start_link(__MODULE__, type, [
      timeout: 30_000, # 30 seconds to init or die
      name: via_tuple(name), # named dictionary (optionally eaiser to lookup)
    ])
    |> start_link_nice()
  end
  def start_link_nice({:ok, pid}), do: {:ok, pid}
  def start_link_nice({:error, {:already_started, pid}}), do: {:ok, pid}
  def start_link_nice({:error, err}), do: {:error, err}

  @doc """
  Get the state of the current process
  """
  def get(pid), do: GenServer.call(pid, {:get})

  @doc """
  Check if a word is a valid beginning of a term
  """
  @timed(key: :auto)
  def is_word_start?(pid, letters) do
    GenServer.call(pid, {:is_word_start?, letters})
  end
  @timed(key: :auto)
  def is_word_full?(pid, letters) do
    GenServer.call(pid, {:is_word_full?, letters})
  end
  @timed(key: :auto)
  def get_all_word_starts(pid, letters) do
    GenServer.call(pid, {:get_all_word_starts, letters})
  end

  ### Server API
  def init({:clone, name}) do
    pid = name |> via_tuple()
    state = GenServer.call(pid, {:get})
    {:ok, state}
  end
  def init(type) do
    allowed = [:scrabble, :wordfeud, :mock]
    case Enum.member?(allowed, type) do
      true -> start_server(type)
      false -> {:error, "Invalid type supplied to Dictionary init #{type}"}
    end
  end
  def handle_call({:get}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:is_word_start?, letters}, _from, state) do
    {:reply, Wordza.Dictionary.Helpers.is_word_start?(letters, state), state}
  end
  def handle_call({:is_word_full?, letters}, _from, state) do
    {:reply, Wordza.Dictionary.Helpers.is_word_full?(letters, state), state}
  end
  def handle_call({:get_all_word_starts, letters}, _from, state) do
    {:reply, Wordza.Dictionary.Helpers.get_all_word_starts(letters, state), state}
  end

  defp start_server(type) do
    Cachex.start_link(type, [
      limit: limit(
        size: 20_000,
        policy: Cachex.Policy.LRW,
        reclaim: 0.1
      )
    ])
    {:ok, Wordza.Dictionary.Helpers.build_dict(type)}
  end

  # Fancy name <-> pid refernce library `gproc`
  defp via_tuple(pid) when is_pid(pid), do: pid
  defp via_tuple(name) when is_atom(name), do: name
  defp via_tuple(name) do
    {:via, :gproc, {:n, :l, {:wordza_dictionary, name}}}
  end

end

defmodule Wordza.Dictionary.Helpers do
  @moduledoc """
  Internal Helper functions for the Dictionary module
  """
  use Elixometer

  @doc """
  Builds a full dictionary map, from a source text file
  WARNING this is super slow... you have been warned
  """
  def build_dict(:mock) do
    [
      "a",
      "alan",
      "all",
    ]
    |> Stream.map(&String.trim/1)
    |> Enum.reduce(%{}, fn (line, dict) -> add_to_dict(dict, line) end)
  end
  def build_dict(:scrabble) do
    "./lib/dictionary/dictionary_scrabble.txt"
    |> File.stream!
    |> Stream.map(&String.trim/1)
    |> Enum.reduce(%{}, fn (line, dict) -> add_to_dict(dict, line) end)
  end
  def build_dict(:wordfeud) do
    # the wordfeud game uses all kinds of stuff scrabble doesn't
    # but I have not yet found the official dictionary
    # so I downloaded from: https://github.com/dwyl/english-words
    "./lib/dictionary/dictionary_dwyl.txt"
    |> File.stream!
    |> Stream.map(&String.trim/1)
    |> Enum.reduce(%{}, fn (line, dict) -> add_to_dict(dict, line) end)
  end

  @doc """
  Is the word at least a part of the word, from the beginning?
  This is a partial lookup in a structured dictionary
  """
  def is_word_start?(nil, _state), do: :no
  def is_word_start?("", _state), do: :no
  def is_word_start?([], _state), do: :no
  def is_word_start?(letters, dict) do
    letters = clean_letters(letters)
    found = dict |> get_in(letters) |> is_map()
    # if we found all of the letters
    case found do
      true -> :ok
      false -> :invalid
    end
  end

  @doc """
  Is the word a full word, found in the dictionary?
  This is a full lookup in a structured dictionary
  """
  def is_word_full?(nil, _state), do: :no
  def is_word_full?("", _state), do: :no
  def is_word_full?([], _state), do: :no
  def is_word_full?(letters, dict) do
    letters = clean_letters(letters)
    # append the :EOW indicator, so we must find that as well
    letters = letters ++ [:EOW]
    found = dict |> get_in(letters) == true
    # if we found all of the letters
    case found do
      true -> :ok
      false -> :invalid
    end
  end

  @doc """
  clean and normalize letter lookup: only strings, only single letters, upper case

  ## Examples

      iex> Wordza.Dictionary.Helpers.clean_letters(["a", "B", "zz"])
      ["A", "B"]
  """
  def clean_letters(letters) when is_bitstring(letters) do
    letters |> String.split("") |> clean_letters()
  end
  def clean_letters(letters) do
    letters
    |> Enum.filter(&is_bitstring/1)
    |> Enum.filter(fn(l) -> String.length(l) == 1 end)
    |> Enum.map(&String.upcase/1)
  end

  @doc """
  Return the all of the first letters that match in a set of letters
  """
  def starts_with_lookup([], _dict), do: []
  def starts_with_lookup(letters, dict) do
    found = get_in(dict, letters)
    cond do
      found == true -> letters
      is_map(found) -> letters
      true ->
        letters
        |> Enum.slice(0, Enum.count(letters) - 1)
        |> starts_with_lookup(dict)
    end
  end

  @doc """
  Add a single (full) word to a dictionary, ready for fast lookup
  - makes upper case cleans term
  - appends a magic :EOW key, so we know it's an end-of-word
  - assigns into the dict structure for letter-based lookup of terms
  """
  def add_to_dict(%{} = dict, word) do
    letters = word |> clean_letters
    # append the :EOW indicator, so we must find that as well for a full word
    letters = letters ++ [:EOW]
    # convert the letters into Access.key functions, setting default values as %{}
    keys = letters |> Enum.map(fn(l) -> Access.key(l, %{}) end)
    put_in(dict, keys, true)
  end

  @doc """
  Find all possible word_starts for a list of letter_sets

  If you had no blanks, the letter_sets from your tray would be 1
  If you had 1 blank, the letter_sets from your tray would be 26
  If you had 2 blanks, the letter_sets from your tray would be 351

  351 is death...
  because we calculate every permutation of every combination of letters

  """
  def get_all_word_starts_for_letter_sets(letter_sets, dict) do
    IO.puts "get_all_word_starts_for_letter_sets not built yet"
  end

  @doc """
  Find all possible word_starts for a list of letters

  NOTE this may be expensive, 7! = 5040 (but is usually not that bad)

  NOTE this doesn't work with blanks...
  """
  @timed(key: :auto)
  def get_all_word_starts(letters, dict) do
    # convert a list of letters into letter_sets
    letters
    |> clean_letters()
    |> Enum.slice(0, 12)
    # should have a single letter_set here (max 12 length)
    |> Comb.permutations()
    |> Enum.to_list()
    # should have a variety of letter_sets here
    |> get_all_word_starts_explode()
    # should have a wild variety of letter_sets here
    |> Enum.sort()
    |> Enum.uniq()
    |> Enum.map(fn(l) -> starts_with_lookup(l, dict) end)
    |> Enum.filter(fn(l) -> Enum.count(l) > 0 end)
    |> Enum.sort()
    |> Enum.uniq()
    |> get_all_word_starts_explode()
    |> Enum.sort()
    |> Enum.uniq()
  end

  @doc """
  Ensure we have every possible "start" path for every word_start

  ## Examples

      iex> word_starts = [["A"], ["A", "L", "L"]]
      iex> Wordza.Dictionary.Helpers.get_all_word_starts_explode(word_starts)
      [["A"], ["A", "L"], ["A", "L", "L"]]
  """
  def get_all_word_starts_explode(word_starts) do
    word_starts
    |> Enum.reduce(word_starts, fn(word_start, acc) ->
      word_start
      |> Enum.reverse()
      |> get_all_word_starts_exploder(acc)
    end)
    |> Enum.filter(fn(l) -> Enum.count(l) > 0 end)
    |> Enum.sort()
    |> Enum.uniq()
  end
  def get_all_word_starts_exploder([], acc), do: acc
  def get_all_word_starts_exploder([letter | word_start_reversed], acc) do
    word_start = word_start_reversed |> Enum.reverse()
    get_all_word_starts_exploder(word_start_reversed, [word_start | acc])
  end

end
