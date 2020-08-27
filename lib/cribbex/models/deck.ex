defmodule Cribbex.Models.Deck do
  alias Cribbex.Models.Card

  def build do
    Enum.flat_map(Card.suits(), fn suit ->
      Enum.map(Card.types(), fn type ->
        Card.build(type, suit)
      end)
    end)
  end

  # yes this is pointless
  def shuffle(deck), do: Enum.shuffle(deck)

  def deal(deck, num_cards \\ 6) do
    do_deal([], deck, num_cards)
  end

  defp do_deal(hand, deck, 0), do: {hand, deck}

  defp do_deal(hand, deck, cards_left) do
    [dealt_card | remaining_deck] = deck
    updated_hand = [dealt_card | hand]
    do_deal(updated_hand, remaining_deck, cards_left - 1)
  end

  # testing, delete this stuff later

  def test_hand do
    build()
    |> shuffle()
    |> deal()
    |> elem(0)
  end

  def flip_and_hand do
    [flip_card | hand] =
      build()
      |> shuffle()
      |> deal(5)
      |> elem(0)

    {flip_card, hand}
  end
end
