defmodule GammonBoard do
  defstruct player_1_checker_count_by_point: nil, player_2_checker_count_by_point: nil

  @doc """
  Generates a new backgammon board. Pass no parameters to get the default starting position.

  Internally, this is represented as a map where the locations of the checkers for both players are relative to
  themselves, as is standard for backgammon, for instance, you will notice both players start with 2 points on their
  respective 24-point.
  """
  def new_board(position \\ :standard_starting_position) do
    case position do
      :standard_starting_position ->
        %GammonBoard{
          player_1_checker_count_by_point: %{24 => 2, 13 => 5, 8 => 3, 5 => 5},
          player_2_checker_count_by_point: %{24 => 2, 13 => 5, 8 => 3, 5 => 5}
        }
    end
  end

  @doc """
  Returns true if the checker moves could be player on this board, otherwise returns false.
  """
  def legal_move?(
        gammon_board = %GammonBoard{},
        player_checker_moves = %GammonBoard.PlayerCheckerMoves{}
      ) do
    # IO.puts(player_checker_moves)

    case(make_move(gammon_board, player_checker_moves)) do
      {:ok, _new_board} ->
        true

      {:error, _error} ->
        false
    end
  end

  @doc """
  Attempts to make a series of checker moves, returning a Result with a new GammonBoard if successful.
  """
  def make_move(
        board = %GammonBoard{
          player_1_checker_count_by_point: player_1_checker_count_by_point,
          player_2_checker_count_by_point: player_2_checker_count_by_point
        },
        %GammonBoard.PlayerCheckerMoves{player: player, checker_moves: checker_moves}
      ) do
    # It is symmetrical, so we grab the respective player / opponent based on whether it is player_1 / player_2.
    {
      player_checker_count_by_point,
      opponent_checkers,
      update_board_with_new_player_checker_count_by_point
    } =
      case player do
        :player_1 ->
          {
            player_1_checker_count_by_point,
            player_2_checker_count_by_point,
            fn new_player_1_checker_count_by_point ->
              {:ok,
               %GammonBoard{
                 board
                 | player_1_checker_count_by_point: new_player_1_checker_count_by_point
               }}
            end
          }

        :player_2 ->
          {
            player_2_checker_count_by_point,
            player_1_checker_count_by_point,
            fn new_player_2_checker_count_by_point ->
              {:ok,
               %GammonBoard{
                 board
                 | player_2_checker_count_by_point: new_player_2_checker_count_by_point
               }}
            end
          }
      end

    new_player_checker_count_by_point_result =
      make_move_for_player(
        player_checker_count_by_point,
        opponent_checkers,
        checker_moves
      )

    case new_player_checker_count_by_point_result do
      {:error, err} ->
        {:error, err}

      {:ok, new_player_checker_count_by_point} ->
        new_board =
          update_board_with_new_player_checker_count_by_point.(new_player_checker_count_by_point)

        {:ok, new_board}
    end
  end

  # Module Private Functions

  # We did all the moves, success, wrap in :ok tuple.
  defp make_move_for_player(player_checker_count_by_point, _opponent_checker_count_by_point, []) do
    {:ok, player_checker_count_by_point}
  end

  defp make_move_for_player(
         player_checker_count_by_point,
         opponent_checker_count_by_point,
         [%GammonBoard.CheckerMove{from: from, to: to} | remaining_checker_moves]
       ) do
    cond do
      !player_checker_count_by_point[from] ->
        {:error, :no_checker_on_that_point}

      player_checker_count_by_point[25] && from !== 25 ->
        {:error, :you_must_move_off_your_checkers_off_the_bar}

      point_taken_by_opponent?(to, opponent_checker_count_by_point) ->
        {:error, :you_cannot_move_on_your_opponents_point}

      to === 0 && !points_can_be_taken_off?(player_checker_count_by_point) ->
        {:error,
         :you_cannot_take_your_checkers_off_until_all_your_checkers_are_in_your_home_board}

      true ->
        player_checker_count_by_point
        |> remove_checker_on_point(from)
        |> add_checker_on_point(to)
        |> make_move_for_player(opponent_checker_count_by_point, remaining_checker_moves)
    end
  end

  # Check legal move helpers

  defp points_can_be_taken_off?(player_checker_count_by_point, point_index \\ 24)

  defp points_can_be_taken_off?(_player_checker_count_by_point, 6) do
    true
  end

  defp points_can_be_taken_off?(player_checker_count_by_point, point_index) do
    if(!is_nil(player_checker_count_by_point[point_index])) do
      false
    else
      points_can_be_taken_off?(player_checker_count_by_point, point_index - 1)
    end
  end

  # Your opponent can not block you from taking checkers off the board (the '0' point).
  defp point_taken_by_opponent?(0, _opponent_checker_count_by_point) do
    false
  end

  defp point_taken_by_opponent?(player_point, opponent_checker_count_by_point)
       when is_integer(player_point) and 1 <= player_point and player_point <= 24 do
    opponent_point = convert_to_opposing_player_point_value(player_point)
    opponent_checker_count = opponent_checker_count_by_point[opponent_point]

    opponent_checker_count !== nil && opponent_checker_count >= 2
  end

  # Misc helpers

  defp remove_checker_on_point(player_checker_count_by_point, point) do
    current_point_value = player_checker_count_by_point[point]

    if(current_point_value === 1) do
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
end
