defmodule Cribbex.DiscardPhaseHandler do
  alias Cribbex.Models.{
    Card,
    Game,
    Player
  }

  def deal(%Game{} = game, n \\ 6) do
    do_deal(game, n)
  end

  # TODO: it'd be fun to do something cooler here, like a low-card draw...
  def set_dealer(%Game{dealer: nil, non_dealer: nil, player_names: player_names} = game) do
    [dealer, non_dealer] =
      player_names
      |> Enum.shuffle()
      |> Enum.map(&%Player{name: &1})

    %{game | dealer: dealer, non_dealer: non_dealer, phase: :discard}
  end

  def set_dealer(%Game{dealer: dealer, non_dealer: non_dealer} = game) do
    %{game | dealer: non_dealer, non_dealer: dealer, phase: :discard}
  end

  def handle_discard(game, card_code, name) do
    game
    |> perform_discard(card_code, name)
    |> maybe_flip_card_and_transition()
    |> maybe_add_heels_score()
  end

  defp do_deal(
         %{
           dealer: %{cards: dealer_cards} = dealer,
           non_dealer: %{cards: non_dealer_cards} = non_dealer
         } = game,
         0
       ) do
    %{
      game
      | dealer: %{dealer | cards: Card.sort(dealer_cards)},
        non_dealer: %{non_dealer | cards: Card.sort(non_dealer_cards)}
    }
  end

  defp do_deal(
         %{
           dealer: %Player{} = dealer,
           non_dealer: %Player{} = non_dealer,
           deck: deck
         } = game,
         n
       ) do
    {non_dealer, deck} = deal_card(non_dealer, deck)
    {dealer, deck} = deal_card(dealer, deck)
    do_deal(%{game | dealer: dealer, non_dealer: non_dealer, deck: deck}, n - 1)
  end

  defp deal_card(player, deck) do
    [card | rest] = deck
    {%{player | cards: [card | player.cards]}, rest}
  end

  defp perform_discard(%{dealer: %{cards: cards, name: name} = dealer, crib: crib} = game, card_code, name) when length(cards) > 4 do
    card = Enum.find(cards, &(&1.code == card_code))
    %{game | dealer: %{dealer | cards: Enum.reject(cards, & &1 == card)}, crib: [card | crib]}
  end

  defp perform_discard(%{non_dealer: %{cards: cards, name: name} = non_dealer, crib: crib} = game, card_code, name) when length(cards) > 4 do
    card = Enum.find(cards, &(&1.code == card_code))
    %{game | non_dealer: %{non_dealer | cards: Enum.reject(cards, & &1 == card)}, crib: [card | crib]}
  end

  defp perform_discard(game, _card_code, _player_role), do: game

  defp maybe_flip_card_and_transition(%{dealer: %{cards: dealer_cards}, non_dealer: %{cards: non_dealer_cards}, deck: deck} = game) when length(dealer_cards) == 4 and length(non_dealer_cards) == 4 do
    {flip_card, updated_deck} = turn_flip_card(deck)
    %{game | flip_card: flip_card, deck: updated_deck, phase: Game.next_phase(game)}
  end

  defp maybe_flip_card_and_transition(game), do: game

  defp maybe_add_heels_score(%{flip_card: %Card{type: "Jack"}, dealer: %{score: score} = dealer} = game) do
    # FIXME: extract this to a scoring module, every score addition needs to
    # check win conditions
    %{game | dealer: %{dealer | score: score + 2}}
  end

  defp maybe_add_heels_score(game), do: game

  # TODO: it'd be cool if this were a player action
  defp turn_flip_card([flip_card | rest_of_deck]), do: {flip_card, rest_of_deck}
end
