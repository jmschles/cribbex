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

  # TODO: might be cleaner to just find the player that has the card that was clicked
  # to avoid this duplication
  def handle_discard(
        %{dealer: %{cards: cards, name: name} = dealer, non_dealer: %{cards: other_cards}, crib: crib, deck: deck} = game,
        card_code,
        name
      )
      when length(cards) > 4 do
    card = Enum.find(cards, &(&1.code == card_code))
    updated_hand = Enum.reject(cards, & &1 == card)
    case done_discarding?(updated_hand, other_cards) do
      true ->
        # TODO: make this better, I'm cheating because I know the deck is shuffled...
        {flip_card, updated_deck} = turn_flip_card(deck)
        %{game | dealer: %{dealer | cards: updated_hand}, crib: [card | crib], flip_card: flip_card, deck: updated_deck}
      false ->
        %{game | dealer: %{dealer | cards: updated_hand}, crib: [card | crib]}
    end
  end

  def handle_discard(
        %{non_dealer: %{cards: cards, name: name} = non_dealer, dealer: %{cards: other_cards}, crib: crib, deck: deck} = game,
        card_code,
        name
      )
      when length(cards) > 4 do
    card = Enum.find(cards, &(&1.code == card_code))
    updated_hand = Enum.reject(cards, & &1 == card)
    case done_discarding?(updated_hand, other_cards) do
      true ->
        {flip_card, updated_deck} = turn_flip_card(deck)
        %{game | non_dealer: %{non_dealer | cards: updated_hand}, crib: [card | crib], flip_card: flip_card, deck: updated_deck}
      false ->
        %{game | non_dealer: %{non_dealer | cards: updated_hand}, crib: [card | crib]}
    end
  end

  def handle_discard(game, _card_code, _name), do: game

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

  defp done_discarding?(cards, other_cards) do
    length(cards ++ other_cards) == 8
  end

  defp turn_flip_card([%Card{type: "Jack"} = flip_card | rest_of_deck]) do
    # TODO: assign points to dealer
    {flip_card, rest_of_deck}
  end

  defp turn_flip_card([flip_card | rest_of_deck]), do: {flip_card, rest_of_deck}
end
