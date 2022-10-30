defmodule Dice do
  def roll() do
    [Enum.random(1..6), Enum.random(1..6)]
  end

  def double?([die_1, die_1]), do: true
  def double?(_dice_roll), do: false
end
