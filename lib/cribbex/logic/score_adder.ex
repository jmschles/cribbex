defmodule Cribbex.Logic.ScoreAdder do
  alias Cribbex.Logic.Notifier

  def add_points(%{dealer: %{score: score} = dealer} = game_data, :dealer, points) do
    %{game_data | dealer: %{dealer | score: score + points, previous_score: score}}
    |> check_win_condition()
  end

  def add_points(%{non_dealer: %{score: score} = non_dealer} = game_data, :non_dealer, points) do
    %{game_data | non_dealer: %{non_dealer | score: score + points, previous_score: score}}
    |> check_win_condition()
  end

  def add_points(%{dealer: %{score: score} = dealer} = game_data, :dealer, points, source) do
    %{game_data | dealer: %{dealer | score: score + points, previous_score: score}}
    |> Notifier.add_notification(:dealer, source, points)
    |> check_win_condition()
  end

  def add_points(%{non_dealer: %{score: score} = non_dealer} = game_data, :non_dealer, points, source) do
    %{game_data | non_dealer: %{non_dealer | score: score + points, previous_score: score}}
    |> Notifier.add_notification(:non_dealer, source, points)
    |> check_win_condition()
  end

  defp check_win_condition(%{dealer: %{score: score, name: name}} = game_data) when score > 120 do
    %{game_data | winner: name}
  end

  defp check_win_condition(%{non_dealer: %{score: score, name: name}} = game_data)
       when score > 120 do
    %{game_data | winner: name}
  end

  defp check_win_condition(game_data), do: game_data
end
