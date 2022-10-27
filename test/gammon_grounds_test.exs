defmodule GammonGroundsTest do
  use ExUnit.Case
  doctest GammonGrounds

  test "A standard opening 6-5 play is legal" do
    board = Board.new_board()

    standard_opening_6_5_play = [
      CheckerMove.new(24, 18),
      CheckerMove.new(18, 13)
    ]

    dice = [6, 5]

    assert Board.legal_turn_move?(board, standard_opening_6_5_play, dice) == true
  end
end
