defmodule Cribbex.DiscardPhaseHandler do
  alias Cribbex.Models.{
    Deck,
    Game,
    Player
  }

  def deal(%Game{} = game, n \\ 6) do
    do_deal(game, n)
  end

  defp do_deal(game, 0), do: game

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
