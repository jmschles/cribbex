defmodule CribbexWeb.Game.BoardComponent do
  use CribbexWeb, :live_component

  @hole_color "black"
  @my_peg_color "blue"
  @opponent_peg_color "red"

  def dot_color(player_data, _opponent_data, column, row) when column in [0, 1] do
    case peg?(player_data, column, row) do
      true -> @my_peg_color
      false -> @hole_color
    end
  end

  def dot_color(_player_data, opponent_data, column, row) when column in [2, 3] do
    case peg?(opponent_data, column, row) do
      true -> @opponent_peg_color
      false -> @hole_color
    end
  end

  def peg?(%{score: current_score, previous_score: previous_score}, column, row) when column in [0, 3] do
    [current_score, previous_score]
    |> Enum.any?(& &1 in [29 - row + 1, 29 - row + 61])
  end

  def peg?(%{score: current_score, previous_score: previous_score}, column, row) when column in [1, 2] do
    [current_score, previous_score]
    |> Enum.any?(& &1 in [row + 31, row + 91])
  end
end
