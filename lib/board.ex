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
  def new(init_board_spec \\ {:standard_starting_position, @player_1}) do
    case init_board_spec do
      {:standard_starting_position, player_to_move} ->
        %Board{
          player_1_checker_count_by_point: %{24 => 2, 13 => 5, 8 => 3, 6 => 5},
          player_2_checker_count_by_point: %{24 => 2, 13 => 5, 8 => 3, 6 => 5},
          player_to_move: player_to_move
        }

      {:manual_position, player_to_move, player_1_checker_count_by_point, player_2_checker_count_by_point} ->
        %Board{
          player_1_checker_count_by_point: player_1_checker_count_by_point,
          player_2_checker_count_by_point: player_2_checker_count_by_point,
          player_to_move: player_to_move
        }
    end
  end

  # Access to player atoms constants outside module.
  def player_1(), do: @player_1
  def player_2(), do: @player_2

  @doc """
  Returns true if the turn move could be played on this board for this dice roll, otherwise returns false.
  """
  def legal_turn_move?(
        board = %Board{},
        turn_move,
        dice_roll
      ) do
    all_legal_turn_moves = generate_all_canonical_legal_turn_moves(board, dice_roll)

    MapSet.member?(all_legal_turn_moves, turn_move_to_canonical_form(turn_move))
  end

  @doc """
  Attempts to make a series of checker moves (turn_move), returning a Result with a new Board if successful.
  """
  def do_turn_move(board = %Board{}, turn_move, dice_roll) do
    canonical_turn_move = turn_move_to_canonical_form(turn_move)

    if(legal_turn_move?(board, canonical_turn_move, dice_roll)) do
      {:ok,
       board
       |> do_legal_checker_moves(canonical_turn_move)
       |> change_player_to_move}
    else
      {:error, :illegal_move}
    end
  end

  # Module Private Functions

  defp generate_all_canonical_legal_turn_moves(board, [die_1, die_1]),
    do: generate_all_canonical_legal_turn_moves(board, [[die_1, die_1, die_1, die_1]], [], MapSet.new())

  defp generate_all_canonical_legal_turn_moves(board, [die_1, die_2]),
    do: generate_all_canonical_legal_turn_moves(board, [[die_1, die_2], [die_2, die_1]], [], MapSet.new())

  # Base case.
  defp generate_all_canonical_legal_turn_moves(
         _board,
         _dice_segments = [[]],
         list_of_board_and_moves,
         all_possibly_legal_turn_moves_acc
       ) do
    all_possibly_legal_turn_moves_acc
    |> insert_move_sequences_into_turn_moves_set(list_of_board_and_moves)
    |> keep_only_largest_turn_moves_in_turn_moves_set()
    |> insert_no_op_move_if_no_legal_moves()
  end

  # Gone through one ordered die roll, save all possible moves and continue on the other.
  defp generate_all_canonical_legal_turn_moves(
         board,
         [[], other_ordered_roll_segment],
         list_of_board_and_moves,
         all_possibly_legal_turn_moves_acc
       ) do
    generate_all_canonical_legal_turn_moves(
      board,
      [other_ordered_roll_segment],
      [],
      all_possibly_legal_turn_moves_acc
      |> insert_move_sequences_into_turn_moves_set(list_of_board_and_moves)
    )
  end

  defp generate_all_canonical_legal_turn_moves(
         board,
         [[die_segment | remaining_die_segments] | other_ordered_roll_segment],
         list_of_board_and_moves,
         all_possibly_legal_turn_moves_acc
       ) do
    if(list_of_board_and_moves == []) do
      # The first checker move for a series of segments, move it on the board and recurse.
      generate_all_canonical_legal_turn_moves(
        board,
        [remaining_die_segments] ++ other_ordered_roll_segment,
        generate_all_move_and_board_combos_for_die_segment(board, die_segment),
        all_possibly_legal_turn_moves_acc
      )
    else
      # The second+ checker move for a series of segments, we must move it on all the possible boards and moves up
      # to this point, and, as always, recurse.
      new_list_of_board_and_moves =
        Enum.reduce(list_of_board_and_moves, [], fn {board_after_moves_so_far, moves_so_far},
                                                    new_list_of_board_and_moves_acc ->
          # Get all next moves.
          all_next_board_and_next_move_combos =
            generate_all_move_and_board_combos_for_die_segment(
              board_after_moves_so_far,
              die_segment,
              List.last(moves_so_far)
            )

          # Append these next moves to existing move sequences, as we want the full chain of moves to get to any given
          # board.
          all_next_board_and_full_move_sequence_combos =
            Enum.map(all_next_board_and_next_move_combos, fn {board_after_next_move, next_move} ->
              {board_after_next_move, moves_so_far ++ next_move}
            end)

          # Add these combos to our accumulator.
          all_next_board_and_full_move_sequence_combos ++ new_list_of_board_and_moves_acc
        end)

      generate_all_canonical_legal_turn_moves(
        board,
        [remaining_die_segments] ++ other_ordered_roll_segment,
        new_list_of_board_and_moves,
        all_possibly_legal_turn_moves_acc
      )
    end
  end

  # Result will be of the shape: [{new_board, [single_checker_move_played]}, ...].
  #
  # NOTE: that the single checker move is kept in a list, this tends to be helpful for recursively building up a list
  #       of moves.
  defp generate_all_move_and_board_combos_for_die_segment(board, die_segment, maybe_last_checker_move \\ nil) do
    max_point_to_move_from = (maybe_last_checker_move && maybe_last_checker_move.from) || 25
    # We use the `max_point_to_move_from` to avoid generating duplicates of turn moves such as:
    #   - [[24, 22], [18, 12]]
    #   - [[18, 12], [24, 12]]
    possibly_movable_checker_locations =
      get_player_to_move_possibly_movable_checker_locations(board, max_point_to_move_from)

    Enum.reduce(
      possibly_movable_checker_locations,
      [],
      fn checker_location, result_acc ->
        checker_destination = Enum.max([0, checker_location - die_segment])
        checker_move = %CheckerMove{from: checker_location, to: checker_destination}

        cond do
          # We use this case to avoid generating duplicates of turn moves such as:
          #  - [[24, 23], [24, 22]]
          #  - [[24, 22], [24, 23]]
          maybe_last_checker_move != nil && maybe_last_checker_move.from == checker_location &&
              checker_destination > maybe_last_checker_move.to ->
            result_acc

          # Cannot move on an opponents point
          player_to_move_point_taken_by_opponent?(board, checker_destination) ->
            result_acc

          # Cannot take checkers off until are checkers are in homeboard.
          checker_destination == 0 && !player_to_move_has_all_checkers_in_home_board?(board) ->
            result_acc

          # You cannot bear off a checker on a point if there are checkers in the homeboard on a greater point and the
          # die is greater than the from-location.
          #
          # Eg. If you have 1 checker on both points 6 and 2, and your opponent has made your 1 point, and you roll a
          #     double 5, you cannot move (you cannot bear off the 1).
          checker_destination == 0 && checker_location != 6 && checker_location - checker_destination != die_segment &&
              player_to_move_has_checker_on_point?(
                board,
                (checker_location + 1)..6
              ) ->
            result_acc

          true ->
            [{do_legal_checker_moves(board, [checker_move]), [checker_move]}] ++ result_acc
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

  defp player_to_move_has_all_checkers_in_home_board?(_board, 6), do: true

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

  defp player_to_move_has_checker_on_point?(board = %Board{}, point_range = %Range{}) do
    player_to_move_checker_count_by_point = get_player_to_move_checker_count_by_points(board)

    Enum.any?(point_range, &(player_to_move_checker_count_by_point[&1] != nil))
  end

  # Misc helpers

  defp insert_move_sequences_into_turn_moves_set(turn_moves_set = %MapSet{}, list_of_board_and_moves) do
    Enum.reduce(list_of_board_and_moves, turn_moves_set, fn {_board, move_sequence}, turn_moves_set_acc ->
      MapSet.put(turn_moves_set_acc, move_sequence)
    end)
  end

  defp insert_no_op_move_if_no_legal_moves(turn_moves_set = %MapSet{}) do
    if(Enum.empty?(turn_moves_set)) do
      MapSet.new([[]])
    else
      turn_moves_set
    end
  end

  defp keep_only_largest_turn_moves_in_turn_moves_set(turn_moves_set = %MapSet{}) do
    if(Enum.empty?(turn_moves_set)) do
      turn_moves_set
    else
      largest_move_size = CheckerMove.checker_moves_size(Enum.max_by(turn_moves_set, &CheckerMove.checker_moves_size/1))

      MapSet.filter(
        turn_moves_set,
        &(CheckerMove.checker_moves_size(&1) == largest_move_size)
      )
    end
  end

  defp update_player_to_move_checker_count_by_point(board = %Board{}, checker_count_by_point_updater) do
    case(board.player_to_move) do
      @player_1 ->
        %{
          board
          | player_1_checker_count_by_point: checker_count_by_point_updater.(board.player_1_checker_count_by_point)
        }

      @player_2 ->
        %{
          board
          | player_2_checker_count_by_point: checker_count_by_point_updater.(board.player_2_checker_count_by_point)
        }
    end
  end

  defp get_player_to_move_possibly_movable_checker_locations(board = %Board{}, max_point_to_move_from) do
    player_to_move_checker_count_by_points = get_player_to_move_checker_count_by_points(board)

    points =
      if(player_to_move_checker_count_by_points[25] != nil) do
        # You must move off the bar first.
        [25]
      else
        # You cannot move a checker that is already off the board.
        Map.delete(player_to_move_checker_count_by_points, 0)
        |> Map.keys()
      end

    Enum.filter(points, &(&1 <= max_point_to_move_from))
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

  defp change_player_to_move(board = %Board{player_to_move: @player_1}), do: %{board | player_to_move: @player_2}
  defp change_player_to_move(board = %Board{player_to_move: @player_2}), do: %{board | player_to_move: @player_1}

  defp turn_move_to_canonical_form(turn_move) do
    Enum.sort_by(turn_move, fn %CheckerMove{from: from, to: to} -> from * -10 - to end)
  end
end
