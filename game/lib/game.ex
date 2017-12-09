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

  @doc """
  Hello world.

  ## Examples

      iex> Wordiverse.Game.hello
      :world

  """
  def hello do
    :world
  end
end
