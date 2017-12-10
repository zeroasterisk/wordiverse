defmodule Wordiverse.GamePlayer do
  @moduledoc """
  This is our Wordiverse GamePlayer

  """
  defstruct [
    id: nil,
    tiles_in_tray: [],
    score: 0,
  ]

  def create(id) do
    %Wordiverse.GamePlayer{
      id: id,
      tiles_in_tray: [],
      score: 0,
    }
  end
end

