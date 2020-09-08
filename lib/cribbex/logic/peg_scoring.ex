defmodule Cribbex.Logic.PegScoring do
  alias Cribbex.Models.PlayedCard
  alias Cribbex.Logic.ScoreAdder

  def score_play(game) do
    role = find_player_role(game)

    game
    |> check_tally(role)
    |> check_pairs(role)
    |> check_runs(role)
  end

  defp check_tally(%{active_played_cards: cards} = game, role) do
    if add_up_to_something_good?(cards) do
      ScoreAdder.add_points(game, role, 2)
    else
      game
    end
  end

  defp check_pairs(%{active_played_cards: cards} = game, role) do
    card_types = Enum.map(cards, & &1.card.type)

    cond do
      n_of_a_kind?(card_types, 4) ->
        ScoreAdder.add_points(game, role, 12)

      n_of_a_kind?(card_types, 3) ->
        ScoreAdder.add_points(game, role, 6)

      n_of_a_kind?(card_types, 2) ->
        ScoreAdder.add_points(game, role, 2)

      true ->
        game
    end
  end

  defp check_runs(%{active_played_cards: cards} = game, role) do
    card_values = Enum.map(cards, & &1.card.run_order)

    case run_length(card_values) do
      n when n >= 3 ->
        ScoreAdder.add_points(game, role, n)

      _ ->
        game
    end
  end

  def run_length(card_values, length \\ 3)

  def run_length(card_values, _length) when length(card_values) < 3, do: 0

  # double check this
  def run_length(card_values, length) when length(card_values) < length, do: length(card_values)

  def run_length(card_values, length) do
    case Enum.take(card_values, length) |> is_run?() do
      true -> run_length(card_values, length + 1)
      false -> length - 1
    end
  end

  def is_run?(card_values) do
    sorted_values = Enum.sort(card_values)

    sorted_values
    |> Enum.with_index()
    |> Enum.map(fn {value, i} -> (Enum.at(sorted_values, i + 1) || 0) - value end)
    |> Enum.drop(-1)
    |> Enum.uniq()
    |> length() == 1
  end

  defp n_of_a_kind?(card_types, n) do
    length(card_types) >= n && Enum.take(card_types, n) |> Enum.uniq() |> length() == 1
  end

  defp add_up_to_something_good?(cards) do
    cards
    |> Enum.map(& &1.card.value)
    |> Enum.sum()
    |> Kernel.in([15, 31])
  end

  defp find_player_role(
         %{
           active_played_cards: [%PlayedCard{played_by: played_by} | _rest]
         } = game
       ) do
    [:dealer, :non_dealer]
    |> Enum.find(& Map.get(game, &1).name == played_by)
  end
end
