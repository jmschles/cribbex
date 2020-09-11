defmodule Cribbex.DiscardPhaseHandler do
  alias Cribbex.Models.{
    Card,
    Game,
    Player
  }

  def start_hand(game) do
    game
    |> set_dealer()
    |> shuffle_deck()
    |> deal()
  end

  def handle_discard(game, card_code, name) do
    game
    |> perform_discard(card_code, name)
    |> maybe_flip_card_and_transition()
    |> maybe_add_heels_score()
  end

  defp deal(%Game{} = game, n \\ 6) do
    do_deal(game, n)
  end

  # TODO: it'd be fun to do something cooler here, like a low-card draw...
  defp set_dealer(%Game{dealer: nil, non_dealer: nil, player_names: player_names} = game) do
    [dealer, non_dealer] =
      player_names
      |> Enum.shuffle()
      |> Enum.map(&%Player{name: &1})

    %{game | dealer: dealer, non_dealer: non_dealer, phase: :discard}
  end

  defp set_dealer(%Game{dealer: dealer, non_dealer: non_dealer} = game) do
    %{game | dealer: non_dealer, non_dealer: dealer, phase: :discard}
  end

  defp shuffle_deck(%{deck: deck} = game) do
    shuffled = 2..6
    |> Enum.random()
    |> shuffle_n_times(deck)

    %{game | deck: shuffled}
  end

  defp shuffle_n_times(0, deck), do: deck

  defp shuffle_n_times(n, deck) do
    shuffle_n_times(n - 1, Enum.shuffle(deck))
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

  defp perform_discard(
         %{dealer: %{cards: cards, name: name} = dealer, crib: crib} = game,
         card_code,
         name
       )
       when length(cards) > 4 do
    card = Enum.find(cards, &(&1.code == card_code))
    %{game | dealer: %{dealer | cards: Enum.reject(cards, &(&1 == card))}, crib: [card | crib]}
  end

  defp perform_discard(
         %{non_dealer: %{cards: cards, name: name} = non_dealer, crib: crib} = game,
         card_code,
         name
       )
       when length(cards) > 4 do
    card = Enum.find(cards, &(&1.code == card_code))

    %{
      game
      | non_dealer: %{non_dealer | cards: Enum.reject(cards, &(&1 == card))},
        crib: [card | crib]
    }
  end

  defp perform_discard(game, _card_code, _player_role), do: game

  defp maybe_flip_card_and_transition(
         %{
           dealer: %{cards: dealer_cards},
           non_dealer: %{cards: non_dealer_cards} = non_dealer,
           deck: deck
         } = game
       )
       when length(dealer_cards) == 4 and length(non_dealer_cards) == 4 do
    {flip_card, updated_deck} = turn_flip_card(deck)

    %{
      game
      | flip_card: flip_card,
        deck: updated_deck,
        phase: Game.next_phase(game),
        non_dealer: %{non_dealer | active: true}
    }
  end

  defp maybe_flip_card_and_transition(game), do: game

  defp maybe_add_heels_score(
         %{flip_card: %Card{type: "Jack"}} = game
       ) do
    Cribbex.Logic.ScoreAdder.add_points(game, :dealer, 2)
  end

  defp maybe_add_heels_score(game), do: game

  # TODO: it'd be cool if this were a player action
  defp turn_flip_card([flip_card | rest_of_deck]), do: {flip_card, rest_of_deck}
end
