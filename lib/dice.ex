defmodule Dice do
  def roll() do
    [Enum.random(1..6), Enum.random(1..6)]
  end

  def double?([die_1, die_2]) do
    die_1 == die_2
  end
end
