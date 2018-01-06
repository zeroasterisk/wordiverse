defmodule GameDictionaryTest do
  use ExUnit.Case
  doctest Wordza.Dictionary
  doctest Wordza.Dictionary.Helpers

  test "basic start_link to get a Dictionary server started" do
    {:ok, pid} = Wordza.Dictionary.start_link(:mock)
    assert is_pid(pid)
    # nicely handle situations where it's already started
    {:ok, pid} = Wordza.Dictionary.start_link(:mock)
    assert is_pid(pid)
  end
  test "basic is_word_start? for a mock dictionary" do
    {:ok, pid} = Wordza.Dictionary.start_link(:mock)
    assert Wordza.Dictionary.is_word_start?(pid, "all") == :ok
    assert Wordza.Dictionary.is_word_start?(pid, "al") == :ok
    assert Wordza.Dictionary.is_word_start?(pid, "alll") == :invalid
  end
  test "basic is_word_full? for a mock dictionary" do
    {:ok, pid} = Wordza.Dictionary.start_link(:mock)
    assert Wordza.Dictionary.is_word_full?(pid, "all") == :ok
    assert Wordza.Dictionary.is_word_full?(pid, "al") == :invalid
    assert Wordza.Dictionary.is_word_full?(pid, "alll") == :invalid
  end
  test "basic get_all_word_starts for a mock dictionary" do
    {:ok, pid} = Wordza.Dictionary.start_link(:mock)
    letters = ["L", "B", "D", "A", "N", "A", "L"]
    assert Wordza.Dictionary.get_all_word_starts(pid, letters) == [
      ["A", "L"],
      ["A"],
      ["A", "L", "A"],
      ["A", "L", "A", "N"],
      ["A", "L", "L"],
    ]
  end

end

defmodule GameDictionaryHelpersTest do
  use ExUnit.Case
  doctest Wordza.Dictionary.Helpers

  defp mock_dictionary() do
    %{
      "A" => %{
        :EOW => true,
        "L" => %{
          "L" => %{
            :EOW => true
          },
          "A" => %{
            "N" => %{
              :EOW => true
            }
          }
        }
      }
    }
  end

  test "basic add word to dictionary" do
    dict = %{}
    assert Wordza.Dictionary.Helpers.add_to_dict(dict, "all") == %{
      "A" => %{
        "L" => %{
          "L" => %{
            :EOW => true
          },
        }
      }
    }
  end

  test "basic is_word_start? for a mock dictionary" do
    dict = mock_dictionary()
    assert Wordza.Dictionary.Helpers.is_word_start?("a", dict) == :ok
    assert Wordza.Dictionary.Helpers.is_word_start?("al", dict) == :ok
    assert Wordza.Dictionary.Helpers.is_word_start?("all", dict) == :ok
    assert Wordza.Dictionary.Helpers.is_word_start?("alll", dict) == :invalid
    assert Wordza.Dictionary.Helpers.is_word_start?("alan", dict) == :ok
    assert Wordza.Dictionary.Helpers.is_word_start?("alan:", dict) == :invalid
  end
  test "basic is_word_full? for a mock dictionary" do
    dict = mock_dictionary()
    assert Wordza.Dictionary.Helpers.is_word_full?("a", dict) == :ok
    assert Wordza.Dictionary.Helpers.is_word_full?("al", dict) == :invalid
    assert Wordza.Dictionary.Helpers.is_word_full?("all", dict) == :ok
    assert Wordza.Dictionary.Helpers.is_word_full?("alll", dict) == :invalid
    assert Wordza.Dictionary.Helpers.is_word_full?("ala", dict) == :invalid
    assert Wordza.Dictionary.Helpers.is_word_full?("alan", dict) == :ok
  end

  test "basic starts_with_lookup for a mock dictionary, ensure we find 'ALL'+EOW" do
    dict = mock_dictionary()
    assert Wordza.Dictionary.Helpers.starts_with_lookup(["A"], dict) == ["A"]
    assert Wordza.Dictionary.Helpers.starts_with_lookup(["A", "L"], dict) == ["A", "L"]
    assert Wordza.Dictionary.Helpers.starts_with_lookup(["A", "L", "L"], dict) == ["A", "L", "L"]
    assert Wordza.Dictionary.Helpers.starts_with_lookup(["A", "L", "L", :EOW], dict) == ["A", "L", "L", :EOW]
  end
  test "basic starts_with_lookup for a mock dictionary, returns up until nothing else found" do
    dict = mock_dictionary()
    assert Wordza.Dictionary.Helpers.starts_with_lookup(["A", "L", "X"], dict) == ["A", "L"]
  end

  test "basic get_all_word_starts from a list of letters" do
    dict = mock_dictionary()
    letters = ["L", "B", "D", "A", "N"]
    assert Wordza.Dictionary.Helpers.get_all_word_starts(letters, dict) == [
      ["A", "L"],
      ["A"]
    ]
    letters = ["L", "B", "D", "A", "N", "A"]
    assert Wordza.Dictionary.Helpers.get_all_word_starts(letters, dict) == [
      ["A", "L"],
      ["A"],
      ["A", "L", "A"],
      ["A", "L", "A", "N"],
    ]
    letters = ["L", "B", "D", "A", "N", "A", "L"]
    assert Wordza.Dictionary.Helpers.get_all_word_starts(letters, dict) == [
      ["A", "L"],
      ["A"],
      ["A", "L", "A"],
      ["A", "L", "A", "N"],
      ["A", "L", "L"],
    ]
  end
end
