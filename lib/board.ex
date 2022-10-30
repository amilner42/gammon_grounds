# TODO:
# - custom positions
# - sanity tests
# - no bearing off if a greater point is available but cannot move

# Is this easy? I can also just manually sort and delete dups.
# - more effecient with move creation, only search from highest move to lowest move to avoid dups of:
#   [ 24 -> 23, 6 - 3 ] and [6 -> 3, 24 -> 23 ]

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
  def new(position \\ :standard_starting_position, player_to_move \\ @player_1) do
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
  def do_turn_move(board = %Board{}, turn_move, dice_roll) do
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

  defp generate_all_legal_turn_moves(board, [die_1, die_1]),
    do: generate_all_legal_turn_moves(board, [[die_1, die_1, die_1, die_1]], [], MapSet.new())

  defp generate_all_legal_turn_moves(board, [die_1, die_2]),
    do: generate_all_legal_turn_moves(board, [[die_1, die_2], [die_2, die_1]], [], MapSet.new())

  # Exhausted the dice segments, just filter out moves that don't use as much of the roll as possible. This is a
  # a rule in the game of backgammon.
  defp generate_all_legal_turn_moves(_board, [[]], list_of_board_and_moves, all_possibly_legal_turn_moves_acc) do
    all_possibly_legal_turn_moves_acc
    |> insert_move_sequences_into_turn_moves_set(list_of_board_and_moves)
    |> keep_only_largest_turn_moves_in_turn_moves_set()
  end

  # Gone through one ordered die roll, save all possible moves and continue on the other.
  defp generate_all_legal_turn_moves(
         board,
         [[], other_ordered_roll_segment],
         list_of_board_and_moves,
         all_possibly_legal_turn_moves_acc
       ) do
    generate_all_legal_turn_moves(
      board,
      [other_ordered_roll_segment],
      [],
      all_possibly_legal_turn_moves_acc
      |> insert_move_sequences_into_turn_moves_set(list_of_board_and_moves)
    )
  end

  defp generate_all_legal_turn_moves(
         board,
         [[die_segment | remaining_die_segments] | other_ordered_roll_segment],
         list_of_board_and_moves,
         all_possibly_legal_turn_moves_acc
       ) do
    if(list_of_board_and_moves == []) do
      # The first checker move for a series of segments, move it on the board and recurse.
      generate_all_legal_turn_moves(
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
              die_segment
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

      generate_all_legal_turn_moves(
        board,
        [remaining_die_segments] ++ other_ordered_roll_segment,
        new_list_of_board_and_moves,
        all_possibly_legal_turn_moves_acc
      )
    end
  end

  # TODO DOC.
  def generate_all_move_and_board_combos_for_die_segment(board, die) do
    possibly_movable_checker_locations = get_player_to_move_possibly_movable_checker_locations(board)

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

  # Misc helpers

  defp insert_move_sequences_into_turn_moves_set(turn_moves_set = %MapSet{}, list_of_board_and_moves) do
    Enum.reduce(list_of_board_and_moves, turn_moves_set, fn {_board, move_sequence}, turn_moves_set_acc ->
      MapSet.put(turn_moves_set_acc, move_sequence)
    end)
  end

  defp keep_only_largest_turn_moves_in_turn_moves_set(turn_moves_set = %MapSet{}) do
    largest_move_size = CheckerMove.checker_moves_size(Enum.max_by(turn_moves_set, &CheckerMove.checker_moves_size/1))

    MapSet.filter(
      turn_moves_set,
      &(CheckerMove.checker_moves_size(&1) == largest_move_size)
    )
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

  def change_player_to_move(board = %Board{player_to_move: @player_1}), do: %{board | player_to_move: @player_2}
  def change_player_to_move(board = %Board{player_to_move: @player_2}), do: %{board | player_to_move: @player_1}
end
