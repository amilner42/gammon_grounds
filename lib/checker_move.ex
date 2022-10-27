defmodule CheckerMove do
  defstruct from: nil, to: nil

  @doc """
  Points 1 - 24.

  Point 0 represents the player taking his checker off the board (final stage of game).
  Point 25 represents sitting on the bar.
  """
  def new(from, to)
      when is_integer(from) and is_integer(to) and
             1 <= from and from <= 25 and
             0 <= to and to <= 24 do
    %CheckerMove{from: from, to: to}
  end

  def checker_moves_size(enumerable_checker_moves) do
    Stream.map(enumerable_checker_moves, &size/1)
    |> Enum.sum()
  end

  def size(%CheckerMove{from: from, to: to}), do: from - to
end
