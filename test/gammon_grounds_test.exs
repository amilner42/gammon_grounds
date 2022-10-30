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

  describe "bearing off" do
    test "You can bear off checkers when all checkers are in the homeboard" do
      board = new_board({:manual_position, player_1(), %{6 => 2, 5 => 1}, %{24 => 2}})
      dice = [6, 5]

      legal_bear_off_turn_move = [
        new_checker_move(6, 0),
        new_checker_move(5, 0)
      ]

      assert legal_turn_move?(board, legal_bear_off_turn_move, dice) == true
    end
  end

  test "You cannot bear off a checker when there is a checker outside the homeboard" do
    board = new_board({:manual_position, player_1(), %{7 => 3, 6 => 2}, %{24 => 2}})
    dice = [6, 1]

    illegal_bear_off_turn_move = [
      new_checker_move(6, 0),
      new_checker_move(6, 5)
    ]

    assert legal_turn_move?(board, illegal_bear_off_turn_move, dice) == false
  end

  test "You cannot bear off a checker when there is a checker left on a greater square" do
    board = new_board({:manual_position, player_1(), %{6 => 1, 4 => 4}, %{24 => 2}})
    dice = [5, 5]

    illegal_bear_off_turn_move = [
      new_checker_move(4, 0),
      new_checker_move(4, 0),
      new_checker_move(4, 0),
      new_checker_move(4, 0)
    ]

    assert legal_turn_move?(board, illegal_bear_off_turn_move, dice) == false
  end
end
