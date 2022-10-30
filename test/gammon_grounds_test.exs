defmodule GammonGroundsTest do
  import GammonGrounds
  use ExUnit.Case
  doctest GammonGrounds

  test "A standard opening 6-5 play is legal" do
    board = new_board()
    dice = [6, 5]
    standard_opening_6_5_play = [new_checker_move(24, 18), new_checker_move(18, 13)]

    assert legal_turn_move?(board, standard_opening_6_5_play, dice) == true
  end

  test "It is illegal to use one die when you can use both" do
    board = new_board()
    dice = [6, 5]
    illegal_single_dice_move = [new_checker_move(24, 18)]

    assert legal_turn_move?(board, illegal_single_dice_move, dice) == false
  end

  test "A legal double die turn move is legal" do
    # This is contrived as you can never get a double on the first roll, but, it's all the same for testing.
    board = new_board()
    dice = [6, 6]

    legal_double_move = [
      new_checker_move(24, 18),
      new_checker_move(24, 18),
      new_checker_move(13, 7),
      new_checker_move(13, 7)
    ]

    assert legal_turn_move?(board, legal_double_move, dice) == true
  end
end
