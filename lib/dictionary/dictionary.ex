defmodule Wordza.Dictionary do
  @moduledoc """
  This is our Wordza.Dictionary
  We only need 1 dictionary, for all of our Games of each type
  So it is it's own GenServer
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
  def start_link(type) do
    out = GenServer.start_link(__MODULE__, type, [
      name: type,
      timeout: 30_000, # 30 seconds to init or die
    ])
    out |> start_link_nice()
  end
  def start_link_nice({:ok, pid}), do: {:ok, pid}
  def start_link_nice({:error, {:already_started, pid}}), do: {:ok, pid}
  def start_link_nice({:error, err}), do: {:error, err}

  @doc """
  Check if a word is a valid beginning of a term
  """
  def is_word_start?(pid, letters) do
    GenServer.call(pid, {:is_word_start?, letters})
  end
  def is_word_full?(pid, letters) do
    GenServer.call(pid, {:is_word_full?, letters})
  end

  ### Server API
  def init(type) do
    allowed = [:scrabble, :wordfeud, :mock]
    case Enum.member?(allowed, type) do
      true -> {:ok, Wordza.Dictionary.Helpers.build_dict(type)}
      false -> {:error, "Invalid type supplied to Dictionary init #{type}"}
    end
  end
  def handle_call({:is_word_start?, str}, _from, state) do
    {:reply, Wordza.Dictionary.Helpers.is_word_start?(str, state), state}
  end
  def handle_call({:is_word_full?, str}, _from, state) do
    {:reply, Wordza.Dictionary.Helpers.is_word_full?(str, state), state}
  end

end

defmodule Wordza.Dictionary.Helpers do
  @moduledoc """
  Internal Helper functions for the Dictionary module
  """

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
    "./lib/dictionary/dictionary_dwly.txt"
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
    found = lookup(letters, dict)
    # if we found all of the letters
    case found == letters do
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
    found = lookup(letters, dict)
    # if we found all of the letters
    case found == letters do
      true -> :ok
      false -> :invalid
    end
  end

  # clean and normalize letter lookup: only strings, only single letters, upper case
  defp clean_letters(letters) when is_bitstring(letters) do
    letters |> String.split("") |> clean_letters()
  end
  defp clean_letters(letters) do
    letters
    |> Enum.filter(&is_bitstring/1)
    |> Enum.filter(fn(l) -> String.length(l) == 1 end)
    |> Enum.map(&String.upcase/1)
  end

  # lookup letters "tofind" and return all "found" letters in the dictionary
  # the dictionary must be structures as a nested lookup map
  defp lookup(tofind, dict), do: lookup(tofind, dict, [])
  defp lookup([] = _tofind, _dict, found), do: Enum.reverse(found)
  defp lookup(tofind, dict, found) do
    {letter, tofind} = tofind |> List.pop_at(0)
    case Map.has_key?(dict, letter) do
      # TODO review this... we are Map.get for the whole dictionary, letter by letter
      #   this could be really RAM intensive... unsure, need to profile
      #   alternative would be to find a way to lookup by every letter in found
      #   like: dict["a"]["l"]["l"]
      true -> lookup(tofind, Map.get(dict, letter), [letter | found])
      false -> []
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
    put_in(dict, keys, nil)
  end
end
