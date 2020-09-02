defmodule Cribbex.DiscardPhaseHandler do
  alias Cribbex.Models.{
    Card,
    Deck,
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
           deck: %Deck{} = deck
         } = game,
         n
       ) do
    {non_dealer, deck} = deal_card(non_dealer, deck)
    {dealer, deck} = deal_card(dealer, deck)
    do_deal(%{game | dealer: dealer, non_dealer: non_dealer, deck: deck}, n - 1)
  end

  defp deal_card(player, deck) do
    %{cards: [card | rest]} = deck
    {%{player | cards: [card | player.cards]}, %{deck | cards: rest}}
  end
end
