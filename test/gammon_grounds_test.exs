defmodule GammonGroundsTest do
  import GammonGrounds
  use ExUnit.Case
  doctest GammonGrounds

  test "A standard opening 6-5 play is legal" do
    board = new_board()

    standard_opening_6_5_play = [
      new_checker_move(24, 18),
      new_checker_move(18, 13)
    ]

    dice = [6, 5]

    assert legal_turn_move?(board, standard_opening_6_5_play, dice) == true
  end
end
