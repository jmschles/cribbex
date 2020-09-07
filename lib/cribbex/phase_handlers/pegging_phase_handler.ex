defmodule Cribbex.PeggingPhaseHandler do
  alias Cribbex.Models.{
    Card,
    PlayedCard
  }

  def handle_play(game, card_code, name) do
    game
    |> validate_play(card_code, name)
    |> perform_play(card_code, name)
    |> check_for_scoring()
    |> reset_error_state()
  end

  # it wasn't your turn
  defp validate_play(%{dealer: %{name: name, active: false}} = game, _card_code, name) do
    Map.put(game, :error, true)
  end

  defp validate_play(%{non_dealer: %{name: name, active: false}} = game, _card_code, name) do
    Map.put(game, :error, true)
  end

  # play would keep the count <= 31
  defp validate_play(game, card_code, _name) do
    if valid_play?(game, card_code) do
      game
    else
      Map.put(game, :error, true)
    end
  end

  defp perform_play(%{error: true} = game, _card_code, _name), do: game

  defp perform_play(%{dealer: %{name: name, cards: cards} = dealer, non_dealer: non_dealer, active_played_cards: active_played_cards} = game, card_code, name) do
    card = Enum.find(cards, &(&1.code == card_code))
    played_card = %PlayedCard{card: card, played_by: name}
    %{game | dealer: %{dealer | cards: cards -- [card], active: false}, non_dealer: %{non_dealer | active: true}, active_played_cards: [played_card | active_played_cards]}
  end

  defp perform_play(%{non_dealer: %{name: name, cards: cards} = non_dealer, dealer: dealer, active_played_cards: active_played_cards} = game, card_code, name) do
    card = Enum.find(cards, &(&1.code == card_code))
    played_card = %PlayedCard{card: card, played_by: name}
    %{game | non_dealer: %{non_dealer | cards: cards -- [card], active: false}, dealer: %{dealer | active: true}, active_played_cards: [played_card | active_played_cards]}
  end

  defp check_for_scoring(%{error: true} = game), do: game

  defp check_for_scoring(game) do
    Cribbex.Logic.PegScoring.score_play(game)
  end

  defp reset_error_state(game), do: %{game | error: nil}

  # helpers

  defp valid_play?(game, card_code) do
    current_count(game) + Card.get_value_by_card_code(card_code) <= 31
  end

  defp current_count(%{active_played_cards: active_played_cards}) do
    active_played_cards
    |> Enum.map(& &1.card.value)
    |> Enum.sum()
  end
end
