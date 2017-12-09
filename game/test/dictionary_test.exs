defmodule GameDictionaryTest do
  use ExUnit.Case
  doctest Wordiverse.Game.Dictionary
  doctest Wordiverse.Game.Dictionary.Helpers

  test "basic start_link to get a Dictionary server started" do
    {:ok, pid} = Wordiverse.Game.Dictionary.start_link(:mock)
    assert is_pid(pid)
    # nicely handle situations where it's already started
    {:ok, pid} = Wordiverse.Game.Dictionary.start_link(:mock)
    assert is_pid(pid)
  end
  test "basic is_word_start? for a mock dictionary" do
    {:ok, pid} = Wordiverse.Game.Dictionary.start_link(:mock)
    assert Wordiverse.Game.Dictionary.is_word_start?(pid, "all") == :ok
    assert Wordiverse.Game.Dictionary.is_word_start?(pid, "al") == :ok
    assert Wordiverse.Game.Dictionary.is_word_start?(pid, "alll") == :invalid
  end
  test "basic is_word_full? for a mock dictionary" do
    {:ok, pid} = Wordiverse.Game.Dictionary.start_link(:mock)
    assert Wordiverse.Game.Dictionary.is_word_full?(pid, "all") == :ok
    assert Wordiverse.Game.Dictionary.is_word_full?(pid, "al") == :invalid
    assert Wordiverse.Game.Dictionary.is_word_full?(pid, "alll") == :invalid
  end

end

defmodule GameDictionaryHelpersTest do
  use ExUnit.Case
  doctest Wordiverse.Game.Dictionary.Helpers

  defp mock_dictionary() do
    %{
      "A" => %{
        :EOW => nil,
        "L" => %{
          "L" => %{
            :EOW => nil
          },
          "A" => %{
            "N" => %{
              :EOW => nil
            }
          }
        }
      }
    }
  end

  test "basic is_word_start? for a mock dictionary" do
    dict = mock_dictionary()
    assert Wordiverse.Game.Dictionary.Helpers.is_word_start?("a", dict) == :ok
    assert Wordiverse.Game.Dictionary.Helpers.is_word_start?("al", dict) == :ok
    assert Wordiverse.Game.Dictionary.Helpers.is_word_start?("all", dict) == :ok
    assert Wordiverse.Game.Dictionary.Helpers.is_word_start?("alll", dict) == :invalid
    assert Wordiverse.Game.Dictionary.Helpers.is_word_start?("alan", dict) == :ok
    assert Wordiverse.Game.Dictionary.Helpers.is_word_start?("alan:", dict) == :invalid
  end
  test "basic is_word_full? for a mock dictionary" do
    dict = mock_dictionary()
    assert Wordiverse.Game.Dictionary.Helpers.is_word_full?("a", dict) == :ok
    assert Wordiverse.Game.Dictionary.Helpers.is_word_full?("al", dict) == :invalid
    assert Wordiverse.Game.Dictionary.Helpers.is_word_full?("all", dict) == :ok
    assert Wordiverse.Game.Dictionary.Helpers.is_word_full?("alll", dict) == :invalid
    assert Wordiverse.Game.Dictionary.Helpers.is_word_full?("ala", dict) == :invalid
    assert Wordiverse.Game.Dictionary.Helpers.is_word_full?("alan", dict) == :ok
  end

  test "basic add word to dictionary" do
    dict = %{}
    assert Wordiverse.Game.Dictionary.Helpers.add_to_dict(dict, "all") == %{
      "A" => %{
        "L" => %{
          "L" => %{
            :EOW => nil
          },
        }
      }
    }
  end
end
