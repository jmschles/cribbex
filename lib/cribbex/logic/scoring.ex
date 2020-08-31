defmodule Cribbex.Logic.Scoring do
  alias Cribbex.Math

  def calculate_score(hand, flip_card, is_crib \\ false) do
    %{}
    |> add_fifteens_score([flip_card | hand])
    |> add_runs_score([flip_card | hand])
    |> add_pairs_score([flip_card | hand])
    |> add_flush_score(flip_card, hand, is_crib)
    |> add_nobs_score(flip_card, hand)
    |> Enum.reject(fn {_score_type, score} -> score == 0 end)
    |> Enum.into(%{})
    |> add_total()
  end

  defp add_fifteens_score(scores, cards) do
    Map.put(scores, :fifteens, fifteens_score(cards))
  end

  defp add_runs_score(scores, cards) do
    Map.put(scores, :runs, runs_score(cards))
  end

  defp add_pairs_score(scores, cards) do
    Map.put(scores, :pairs, pairs_score(cards))
  end

  defp add_flush_score(scores, flip_card, hand, is_crib) do
    Map.put(scores, :flush, flush_score(flip_card, hand, is_crib))
  end

  defp add_nobs_score(scores, flip_card, hand) do
    Map.put(scores, :his_nobs, nobs_score(flip_card, hand))
  end

  defp add_total(scores), do: Map.put(scores, :total, Map.values(scores) |> Enum.sum())

  # calculations

  defp fifteens_score(cards) do
    cards
    |> Enum.map(& &1.value)
    |> Math.subsets()
    |> Enum.count(&(Enum.sum(&1) == 15))
    |> (&(&1 * 2)).()
  end

  defp runs_score(cards) do
    sorted_run_values = Enum.map(cards, & &1.run_order) |> Enum.sort()

    sorted_run_values
    |> Enum.with_index()
    |> Enum.map(fn {value, i} -> (Enum.at(sorted_run_values, i + 1) || 0) - value end)
    |> Enum.drop(-1)
    |> scan_for_runs()
  end

  defp pairs_score(cards) do
    cards
    |> Enum.group_by(& &1.type)
    |> Map.values()
    |> Enum.map(&length/1)
    |> Enum.map(&pair_points/1)
    |> Enum.sum()
  end

  defp pair_points(1), do: 0
  defp pair_points(2), do: 2
  defp pair_points(3), do: 6
  defp pair_points(4), do: 12

  defp flush_score(flip_card, hand, false) do
    cond do
      flush?([flip_card | hand]) -> 5
      flush?(hand) -> 4
      true -> 0
    end
  end

  defp flush_score(flip_card, hand, true) do
    if flush?([flip_card | hand]), do: 5, else: 0
  end

  defp nobs_score(flip_card, hand) do
    if has_right_jack?(flip_card, hand), do: 1, else: 0
  end

  # helpers

  defp has_right_jack?(flip_card, hand) do
    hand
    |> Enum.filter(&(&1.type == "Jack"))
    |> Enum.any?(&(&1.suit == flip_card.suit))
  end

  defp flush?(cards) do
    cards
    |> Enum.map(& &1.suit)
    |> Enum.uniq()
    |> length() == 1
  end

  defp scan_for_runs(list, score \\ 0, data \\ %{streak: 1, multiplier: 1, prev_zero: false}) do
    do_run_scan(list, score, data)
  end

  defp do_run_scan([], score, %{streak: streak, multiplier: multiplier}) do
    streak_score(score, streak, multiplier)
  end

  defp do_run_scan(
         [head | tail],
         score,
         data = %{streak: streak, multiplier: multiplier, prev_zero: prev_zero}
       ) do
    case head do
      1 ->
        do_run_scan(tail, score, %{data | streak: streak + 1, prev_zero: false})

      0 ->
        do_run_scan(tail, score, %{
          data
          | multiplier: new_multiplier(multiplier, prev_zero),
            prev_zero: true
        })

      _ ->
        do_run_scan(tail, streak_score(score, streak, multiplier), %{
          data
          | streak: 1,
            multiplier: 1,
            prev_zero: false
        })
    end
  end

  defp new_multiplier(current_multiplier, true), do: current_multiplier + 1
  defp new_multiplier(current_multiplier, false), do: current_multiplier * 2

  defp streak_score(score, streak, multiplier) when streak >= 3, do: score + streak * multiplier
  defp streak_score(score, _streak, _multiplier), do: score
end
