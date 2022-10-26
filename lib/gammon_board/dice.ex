defmodule GammonBoard.Dice do
  def roll() do
    [Enum.random(1..6), Enum.random(1..6)]
  end

  def convert_roll_to_segments([die_1, die_2]) do
    cond do
      # In gammon, doubles give you double the moves.
      die_1 == die_2 ->
        [die_1, die_1, die_1, die_1]

      die_1 > die_2 ->
        [die_1, die_2]

      true ->
        [die_2, die_1]
    end
  end
end
