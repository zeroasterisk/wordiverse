defmodule TourneySchedulerTest do

  use ExUnit.Case
  doctest Wordza.TourneyScheduler

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
    end
  end
end
