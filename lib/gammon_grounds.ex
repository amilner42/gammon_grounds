defmodule GammonGrounds do
  @moduledoc """
  The entry point for all your bg needs.
  """

  defdelegate new_board, to: Board, as: :new
  defdelegate new_board(position), to: Board, as: :new
  defdelegate legal_turn_move?(board, turn_move, dice_roll), to: Board

  defdelegate new_checker_move(from_point, to_point), to: CheckerMove, as: :new
end
