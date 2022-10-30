# TODO:
# - more tests

defmodule GammonGroundsTest do
  import GammonGrounds
  use ExUnit.Case
  doctest GammonGrounds

  setup_all do
    %{
      list_of_tests_as_data: [
        [
          "A standard opening 6-5 play is legal",
          new_board(),
          [6, 5],
          [new_checker_move(24, 18), new_checker_move(18, 13)],
          true
        ],
        [
          "It is illegal to use one die when you can use both",
          new_board(),
          [6, 5],
          [new_checker_move(24, 18)],
          false
        ],
        # This is contrived as you can never get a double on the first roll, but, it's all the same for testing.
        [
          "A legal double die turn move is legal",
          new_board(),
          [6, 6],
          [new_checker_move(24, 18), new_checker_move(24, 18), new_checker_move(13, 7), new_checker_move(13, 7)],
          true
        ],
        [
          "Empty turn is legal when there is no move because you are blocked by opponent",
          new_board({:manual_position, player_1(), %{6 => 2}, %{24 => 2}}),
          [5, 5],
          [],
          true
        ],
        [
          "Empty turn is legal when there is no move because you cannot enter the board",
          new_board({:manual_position, player_1(), %{25 => 2, 12 => 2}, %{1 => 2, 6 => 2}}),
          [6, 1],
          [],
          true
        ],
        [
          "You can bear off checkers when all checkers are in the homeboard",
          new_board({:manual_position, player_1(), %{6 => 2, 5 => 1}, %{24 => 2}}),
          [6, 5],
          [new_checker_move(6, 0), new_checker_move(5, 0)],
          true
        ],
        [
          "You cannot bear off a checker when there is a checker outside the homeboard",
          new_board({:manual_position, player_1(), %{7 => 3, 6 => 2}, %{24 => 2}}),
          [6, 1],
          [new_checker_move(6, 0), new_checker_move(6, 5)],
          false
        ],
        [
          "You cannot bear off a checker when there is a checker left on a greater square",
          new_board({:manual_position, player_1(), %{6 => 1, 4 => 4}, %{24 => 2}}),
          [5, 5],
          [new_checker_move(4, 0), new_checker_move(4, 0), new_checker_move(4, 0), new_checker_move(4, 0)],
          false
        ]
      ]
    }
  end

  describe "#legal_move?" do
    test "Test as data defined in list_of_tests_as_data", %{list_of_tests_as_data: list_of_tests_as_data} do
      {actual_results, expected_results} =
        Enum.reduce(list_of_tests_as_data, {%{}, %{}}, fn [test_description, board, dice, turn_move, is_legal],
                                                          {actual_results, expected_results} ->
          {
            Map.put(actual_results, test_description, legal_turn_move?(board, turn_move, dice)),
            Map.put(expected_results, test_description, is_legal)
          }
        end)

      assert actual_results == expected_results
    end
  end
end
