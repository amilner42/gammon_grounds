defmodule Board do
  @player_1 :player_1
  @player_2 :player_2

  defstruct player_1_checker_count_by_point: nil,
            player_2_checker_count_by_point: nil,
            player_to_move: nil

  @doc """
  Generates a new backgammon board. Pass no parameters to get the default starting position.

  Internally, this is represented as a map where the locations of the checkers for both players are relative to
  themselves, as is standard for backgammon, for instance, you will notice both players start with 2 points on their
  respective 24-point.
  """
  def new_board(position \\ :standard_starting_position, player_to_move \\ @player_1) do
    case position do
      :standard_starting_position ->
        %Board{
          player_1_checker_count_by_point: %{24 => 2, 13 => 5, 8 => 3, 6 => 5},
          player_2_checker_count_by_point: %{24 => 2, 13 => 5, 8 => 3, 6 => 5},
          player_to_move: player_to_move
        }
    end
  end

  @doc """
  Returns true if the turn move could be played on this board for this dice roll, otherwise returns false.
  """
  def legal_turn_move?(
        board = %Board{},
        turn_move,
        dice_roll
      ) do
    all_legal_turn_moves = generate_all_legal_turn_moves(board, dice_roll)

    IO.inspect(all_legal_turn_moves)
    IO.inspect(turn_move)

    MapSet.member?(all_legal_turn_moves, turn_move)
  end

  @doc """
  Attempts to make a series of checker moves (turn_move), returning a Result with a new Board if successful.
  """
  def do_turn_move(
        board = %Board{},
        turn_move,
        dice_roll
      ) do
    if(legal_turn_move?(board, turn_move, dice_roll)) do
      {:ok,
       board
       |> do_legal_checker_moves(turn_move)
       |> change_player_to_move}
    else
      {:error, :illegal_move}
    end
  end

  # Module Private Functions

  defp generate_all_legal_turn_moves(board, dice_roll) do
    dice_segments = Dice.convert_roll_to_segments(dice_roll)

    if(Dice.double?(dice_roll)) do
      generate_all_legal_turn_moves(board, dice_segments, :double)
    else
      generate_all_legal_turn_moves(board, dice_segments, :non_double)
    end
  end

  # TODO DOC
  defp generate_all_legal_turn_moves(board, dice_segments, :double) do
    # pseudo code:
    # go through all of player_to_moves points.
    # try to move each available point a dice_segment distance.
    #   if not possible, carry on to next point.
    #   if possible,

    MapSet.new()
  end

  # TODO DOC
  defp generate_all_legal_turn_moves(board, [die_1, die_2], :non_double) do
    # USe a helper to get all the moves starting with each die.
    all_possibly_legal_turn_moves =
      MapSet.union(
        generate_all_possibly_legal_turn_moves_for_dice_in_order(board, [die_1, die_2]),
        generate_all_possibly_legal_turn_moves_for_dice_in_order(board, [die_2, die_1])
      )

    # In backgammon, you must always use as much of your dice as possible, hence we must do an additional (annoying)
    # check to make sure they made the largest move possible.
    largest_move_size =
      CheckerMove.checker_moves_size(
        Enum.max_by(all_possibly_legal_turn_moves, &CheckerMove.checker_moves_size/1)
      )

    MapSet.filter(
      all_possibly_legal_turn_moves,
      &(CheckerMove.checker_moves_size(&1) == largest_move_size)
    )
  end

  # TODO Doc.
  # Returns MapSet of
  defp generate_all_possibly_legal_turn_moves_for_dice_in_order(board, [die_1, die_2]) do
    all_move_and_board_combos_for_die_1 = generate_all_move_and_board_combos_for_die(board, die_1)

    if(Enum.empty?(all_move_and_board_combos_for_die_1)) do
      # If you cannot move at all, return an empty set of moves.
      MapSet.new()
    else
      Enum.reduce(
        all_move_and_board_combos_for_die_1,
        MapSet.new(),
        fn {board_after_move_1, move_1}, checker_moves_accumulator ->
          all_checker_moves_with_die_2_second =
            generate_all_move_and_board_combos_for_die(board_after_move_1, die_2)

          if(Enum.empty?(all_checker_moves_with_die_2_second)) do
            # If you cannot play the second die, simply save the one move to the move accumulator.
            MapSet.put(checker_moves_accumulator, [move_1])
          else
            Enum.reduce(
              all_checker_moves_with_die_2_second,
              checker_moves_accumulator,
              fn {_board_after_move_2, move_2}, checker_moves_accumulator ->
                MapSet.put(checker_moves_accumulator, [move_1, move_2])
              end
            )
          end
        end
      )
    end
  end

  # TODO DOC.
  def generate_all_move_and_board_combos_for_die(board, die) do
    possibly_movable_checker_locations =
      get_player_to_move_possibly_movable_checker_locations(board)

    Enum.reduce(
      possibly_movable_checker_locations,
      [],
      fn checker_location, result_acc ->
        checker_destination = Enum.max([0, checker_location - die])
        checker_move = %CheckerMove{from: checker_location, to: checker_destination}

        cond do
          # Cannot move on an opponents point
          player_to_move_point_taken_by_opponent?(board, checker_destination) ->
            result_acc

          # Cannot take checkers off until are checkers are in homeboard.
          checker_destination == 0 && !player_to_move_has_all_checkers_in_home_board?(board) ->
            result_acc

          # Add case for bearing off where you cannot move the 6 point because you are blocked on the 1 but
          # you could move the 5 point. This is illegal.
          # checker_destination == 0 &&

          true ->
            [{do_legal_checker_moves(board, [checker_move]), checker_move}] ++ result_acc
        end
      end
    )
  end

  defp do_legal_checker_moves(board = %Board{}, []), do: board

  defp do_legal_checker_moves(board, [%CheckerMove{from: from, to: to} | remaining_checker_moves]) do
    update_player_to_move_checker_count_by_point(
      board,
      fn checker_count_by_point ->
        checker_count_by_point
        |> remove_checker_on_point(from)
        |> add_checker_on_point(to)
      end
    )
    |> do_legal_checker_moves(remaining_checker_moves)
  end

  # Check legal move helpers

  defp player_to_move_has_all_checkers_in_home_board?(board, point_index \\ 25)

  defp player_to_move_has_all_checkers_in_home_board?(_board, 6) do
    true
  end

  defp player_to_move_has_all_checkers_in_home_board?(board, point_index) do
    if(player_to_move_has_any_checkers_on_point(board, point_index)) do
      false
    else
      player_to_move_has_all_checkers_in_home_board?(board, point_index - 1)
    end
  end

  defp player_to_move_has_any_checkers_on_point(
         %Board{
           player_to_move: @player_1,
           player_1_checker_count_by_point: player_1_checker_count_by_point
         },
         point
       ) do
    player_1_checker_count_by_point[point] != nil
  end

  defp player_to_move_has_any_checkers_on_point(
         %Board{
           player_to_move: @player_2,
           player_2_checker_count_by_point: player_2_checker_count_by_point
         },
         point
       ) do
    player_2_checker_count_by_point[point] != nil
  end

  # Your opponent can not block you from taking checkers off the board (the '0' point).
  defp player_to_move_point_taken_by_opponent?(_board, 0), do: false

  defp player_to_move_point_taken_by_opponent?(board, player_point)
       when is_integer(player_point) and 1 <= player_point and player_point <= 24 do
    opponent_point = convert_to_opposing_player_point_value(player_point)
    opponent_checker_count_by_point = get_player_opponent_checker_count_by_points(board)
    opponent_checker_count_on_point = opponent_checker_count_by_point[opponent_point]

    opponent_checker_count_on_point != nil && opponent_checker_count_on_point >= 2
  end

  # Misc helpers

  defp update_player_to_move_checker_count_by_point(
         board = %Board{},
         checker_count_by_point_updater
       ) do
    case(board.player_to_move) do
      @player_1 ->
        %{
          board
          | player_1_checker_count_by_point:
              checker_count_by_point_updater.(board.player_1_checker_count_by_point)
        }

      @player_2 ->
        %{
          board
          | player_2_checker_count_by_point:
              checker_count_by_point_updater.(board.player_2_checker_count_by_point)
        }
    end
  end

  defp get_player_to_move_possibly_movable_checker_locations(board = %Board{}) do
    player_to_move_checker_count_by_points = get_player_to_move_checker_count_by_points(board)

    if(player_to_move_checker_count_by_points[25] != nil) do
      # You must move off the bar first.
      [25]
    else
      # You cannot move a checker that is already off the board.
      Map.delete(player_to_move_checker_count_by_points, 0)
      |> Map.keys()
    end
  end

  defp get_player_to_move_checker_count_by_points(%Board{
         player_to_move: @player_1,
         player_1_checker_count_by_point: player_1_checker_count_by_point
       }) do
    player_1_checker_count_by_point
  end

  defp get_player_to_move_checker_count_by_points(%Board{
         player_to_move: @player_2,
         player_2_checker_count_by_point: player_2_checker_count_by_point
       }) do
    player_2_checker_count_by_point
  end

  defp get_player_opponent_checker_count_by_points(%Board{
         player_to_move: @player_1,
         player_2_checker_count_by_point: player_2_checker_count_by_point
       }) do
    player_2_checker_count_by_point
  end

  defp get_player_opponent_checker_count_by_points(%Board{
         player_to_move: @player_2,
         player_1_checker_count_by_point: player_1_checker_count_by_point
       }) do
    player_1_checker_count_by_point
  end

  defp remove_checker_on_point(player_checker_count_by_point, point) do
    current_point_value = player_checker_count_by_point[point]

    if(current_point_value == 1) do
      # We remove empty points from the map. We never keep 0.
      Map.delete(player_checker_count_by_point, point)
    else
      Map.put(player_checker_count_by_point, point, current_point_value - 1)
    end
  end

  defp add_checker_on_point(player_checker_count_by_point, point) do
    Map.update(
      player_checker_count_by_point,
      point,
      0,
      &(&1 + 1)
    )
  end

  defp convert_to_opposing_player_point_value(point)
       when is_integer(point) and 1 <= point and point <= 24 do
    25 - point
  end

  def change_player_to_move(board = %Board{player_to_move: @player_1}) do
    %{board | player_to_move: @player_2}
  end

  def change_player_to_move(board = %Board{player_to_move: @player_2}) do
    %{board | player_to_move: @player_1}
  end
end
