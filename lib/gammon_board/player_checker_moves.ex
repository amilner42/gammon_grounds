defmodule GammonBoard.PlayerCheckerMoves do
  defstruct player: nil, checker_moves: [], dice_segments: nil

  def new(player, checker_moves, dice_roll)
      when is_atom(player) and is_list(checker_moves) and is_list(dice_roll) do
    dice_segments = GammonBoard.Dice.convert_roll_to_segments(dice_roll)

    %GammonBoard.PlayerCheckerMoves{
      player: player,
      checker_moves: checker_moves,
      dice_segments: dice_segments
    }
  end
end
