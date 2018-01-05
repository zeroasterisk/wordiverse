defmodule Wordza.GamePlayer do
  @moduledoc """
  This is our Wordza GamePlayer

  """
  defstruct [
    id: nil,
    tiles_in_tray: [],
    score: 0,
  ]

  def create(id) do
    %Wordza.GamePlayer{
      id: id,
      tiles_in_tray: [],
      score: 0,
    }
  end
end

