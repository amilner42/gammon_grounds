defmodule GammonBoard.PlayerCheckerMoves do
  defstruct player: nil, checker_moves: []

  def new(player, checker_moves) when is_atom(player) and is_list(checker_moves) do
    %GammonBoard.PlayerCheckerMoves{player: player, checker_moves: checker_moves}
  end
end
