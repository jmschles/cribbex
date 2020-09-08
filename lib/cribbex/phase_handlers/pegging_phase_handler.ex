defmodule Cribbex.PeggingPhaseHandler do
  alias Cribbex.Models.{
    Card,
    PlayedCard
  }

  alias Cribbex.Logic.{
    PegScoring,
    ScoreAdder
  }

  def handle_play(game, card_code, name) do
    game
    |> validate_play(card_code, name)
    |> perform_play(card_code, name)
    |> check_for_scoring()
    |> check_for_thirty_one_reset()
    |> check_for_phase_completion()
    |> reset_error_state()
  end

  def handle_go_check(game) do
    game
    |> can_play?()
    |> maybe_say_go(game)
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

  defp perform_play(
         %{
           dealer: %{name: name, cards: cards} = dealer,
           non_dealer: non_dealer,
           active_played_cards: active_played_cards
         } = game,
         card_code,
         name
       ) do
    card = Enum.find(cards, &(&1.code == card_code))
    played_card = %PlayedCard{card: card, played_by: name}

    %{
      game
      | dealer: %{dealer | cards: cards -- [card], active: false},
        non_dealer: %{non_dealer | active: true},
        active_played_cards: [played_card | active_played_cards]
    }
  end

  defp perform_play(
         %{
           non_dealer: %{name: name, cards: cards} = non_dealer,
           dealer: dealer,
           active_played_cards: active_played_cards
         } = game,
         card_code,
         name
       ) do
    card = Enum.find(cards, &(&1.code == card_code))
    played_card = %PlayedCard{card: card, played_by: name}

    %{
      game
      | non_dealer: %{non_dealer | cards: cards -- [card], active: false},
        dealer: %{dealer | active: true},
        active_played_cards: [played_card | active_played_cards]
    }
  end

  defp check_for_scoring(%{error: true} = game), do: game

  defp check_for_scoring(game) do
    PegScoring.score_play(game)
  end

  defp check_for_thirty_one_reset(%{active_played_cards: active_played_cards} = game) do
    case hit_thirty_one?(active_played_cards) do
      true -> reset(game)
      false -> game
    end
  end

  defp check_for_phase_completion(
         %{
           dealer: %{cards: [], name: dealer_name} = dealer,
           non_dealer: %{cards: [], name: non_dealer_name} = non_dealer,
           active_played_cards: active_played_cards,
           inactive_played_cards: inactive_played_cards
         } = game
       ) do
    all_played_cards = active_played_cards ++ inactive_played_cards

    %{
      game
      | dealer: %{
          dealer
          | active: false,
            said_go: false,
            cards: reassign_cards(all_played_cards, dealer_name)
        },
        non_dealer: %{
          non_dealer
          | active: false,
            said_go: false,
            cards: reassign_cards(all_played_cards, non_dealer_name)
        },
        active_played_cards: [],
        inactive_played_cards: [],
        phase: :scoring
    }
  end

  defp check_for_phase_completion(game), do: game

  defp reset_error_state(game), do: %{game | error: nil}

  defp can_play?(%{dealer: %{active: true, cards: cards}} = game) do
    Enum.any?(cards, &valid_play?(game, &1.code))
  end

  defp can_play?(%{non_dealer: %{active: true, cards: cards}} = game) do
    Enum.any?(cards, &valid_play?(game, &1.code))
  end

  # TODO: add clauses to say go when out of cards
  defp maybe_say_go(
         false,
         %{dealer: %{active: true}, non_dealer: %{said_go: true}} = game
       ) do
    ScoreAdder.add_points(game, :dealer, 1)
    reset(game)
  end

  defp maybe_say_go(
         false,
         %{non_dealer: %{active: true}, dealer: %{said_go: true}} = game
       ) do
    ScoreAdder.add_points(game, :non_dealer, 1)
    reset(game)
  end

  defp maybe_say_go(false, %{dealer: %{active: true} = dealer, non_dealer: non_dealer} = game) do
    %{
      game
      | dealer: %{dealer | said_go: true, active: false},
        non_dealer: %{non_dealer | active: true}
    }
  end

  defp maybe_say_go(false, %{non_dealer: %{active: true} = non_dealer, dealer: dealer} = game) do
    %{
      game
      | non_dealer: %{non_dealer | said_go: true, active: false},
        dealer: %{dealer | active: true}
    }
  end

  defp maybe_say_go(true, _game), do: :noop

  # helpers

  defp valid_play?(game, card_code) do
    current_count(game) + Card.get_value_by_card_code(card_code) <= 31
  end

  defp current_count(%{active_played_cards: active_played_cards}) do
    active_played_cards
    |> Enum.map(& &1.card.value)
    |> Enum.sum()
  end

  defp hit_thirty_one?(cards) do
    cards
    |> Enum.map(& &1.card.value)
    |> Enum.sum() == 31
  end

  defp reassign_cards(played_cards, name) do
    played_cards
    |> Enum.filter(&(&1.played_by == name))
    |> Enum.map(& &1.card)
    |> Card.sort()
  end

  defp reset(
         %{
           dealer: %{name: name} = dealer,
           non_dealer: non_dealer,
           active_played_cards: [%{played_by: name} | _rest] = active_played_cards,
           inactive_played_cards: inactive_played_cards
         } = game
       ) do
    %{
      game
      | dealer: %{dealer | active: false, said_go: false},
        non_dealer: %{non_dealer | active: true, said_go: false},
        active_played_cards: [],
        inactive_played_cards: active_played_cards ++ inactive_played_cards
    }
  end

  defp reset(
         %{
           dealer: dealer,
           non_dealer: %{name: name} = non_dealer,
           active_played_cards: [%{played_by: name} | _rest] = active_played_cards,
           inactive_played_cards: inactive_played_cards
         } = game
       ) do
    %{
      game
      | dealer: %{dealer | active: true, said_go: false},
        non_dealer: %{non_dealer | active: false, said_go: false},
        active_played_cards: [],
        inactive_played_cards: active_played_cards ++ inactive_played_cards
    }
  end
end
