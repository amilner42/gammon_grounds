defmodule GammonGroundsTest do
  use ExUnit.Case
  doctest GammonGrounds

  test "greets the world" do
    assert GammonGrounds.hello() == :world
  end

  test "no move is a legal move" do
    board = GammonBoard.new_board()
    empty_move = GammonBoard.PlayerCheckerMoves.new(:player_1, [], [1, 2])

    assert GammonBoard.legal_move?(board, empty_move) == true
  end

  test "moving to nearby empty square is legal" do
    board = GammonBoard.new_board()

    move_to_open_square =
      GammonBoard.PlayerCheckerMoves.new(
        :player_1,
        [%GammonBoard.CheckerMove{from: 24, to: 23}],
        [1, 2]
      )

    assert GammonBoard.legal_move?(board, move_to_open_square) == true
  end

  test "taking off checker before all checkers are in the homeboard is not legal" do
    board = GammonBoard.new_board()

    move_checker_off_board =
      GammonBoard.PlayerCheckerMoves.new(
        :player_1,
        [%GammonBoard.CheckerMove{from: 5, to: 0}],
        [5, 3]
      )

    assert GammonBoard.legal_move?(board, move_checker_off_board) == false
  end

  test "moving checker onto opponents point is not legal" do
    board = GammonBoard.new_board()

    move_to_opponents_point =
      GammonBoard.PlayerCheckerMoves.new(
        :player_1,
        [%GammonBoard.CheckerMove{from: 5, to: 1}],
        [4, 2]
      )

    assert GammonBoard.legal_move?(board, move_to_opponents_point) == false
  end
end
