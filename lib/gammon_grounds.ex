defmodule GammonGrounds do
  @moduledoc """
  The entry point for all your bg needs. You should interface with everything through this top level module.
  """
  defdelegate new_board, to: Board, as: :new
  defdelegate new_board(init_board_spec), to: Board, as: :new
  defdelegate player_1, to: Board
  defdelegate player_2, to: Board
  defdelegate legal_turn_move?(board, turn_move, dice_roll), to: Board

  defdelegate new_checker_move(from_point, to_point), to: CheckerMove, as: :new
end
