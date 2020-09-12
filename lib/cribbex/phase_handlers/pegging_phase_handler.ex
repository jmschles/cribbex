defmodule Cribbex.PeggingPhaseHandler do
  alias Cribbex.Models.{
    Card,
    Game,
    PlayedCard
  }

  alias Cribbex.Logic.{
    Notifier,
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
      | dealer: %{dealer | cards: cards -- [card], active: false, notifications: []},
        non_dealer: %{non_dealer | active: true, notifications: []},
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
      | non_dealer: %{non_dealer | cards: cards -- [card], active: false, notifications: []},
        dealer: %{dealer | active: true, notifications: []},
        active_played_cards: [played_card | active_played_cards]
    }
  end

  defp check_for_scoring(%{error: true} = game), do: game

  defp check_for_scoring(game) do
    PegScoring.score_play(game)
  end

  defp check_for_thirty_one_reset(game) do
    case hit_thirty_one?(game) do
      true -> reset(game)
      false -> game
    end
  end

  defp check_for_phase_completion(%{dealer: %{cards: []}, non_dealer: %{cards: []}} = game) do
    game
    |> maybe_award_final_go()
    |> complete_phase()
    |> Game.initiate_scoring_phase()
  end

  defp check_for_phase_completion(game), do: game

  defp reset_error_state(game), do: %{game | error: nil}

  defp can_play?(%{dealer: %{active: true, cards: cards}} = game) do
    Enum.any?(cards, &valid_play?(game, &1.code))
  end

  defp can_play?(%{non_dealer: %{active: true, cards: cards}} = game) do
    Enum.any?(cards, &valid_play?(game, &1.code))
  end

  # both said go, point awarded
  defp maybe_say_go(
         false,
         %{dealer: %{active: true}, non_dealer: %{said_go: true}} = game
       ) do
    game
    |> ScoreAdder.add_points(:dealer, 1, "go")
    |> reset()
  end

  defp maybe_say_go(
         false,
         %{non_dealer: %{active: true}, dealer: %{said_go: true}} = game
       ) do
    game
    |> ScoreAdder.add_points(:non_dealer, 1, "go")
    |> reset()
  end

  # player can't go but opponent can
  defp maybe_say_go(false, %{dealer: %{active: true} = dealer, non_dealer: non_dealer} = game) do
    %{
      game
      | dealer: %{dealer | said_go: true, active: false},
        non_dealer: %{non_dealer | active: true}
    }
    |> Notifier.add_notification(:dealer, "go")
  end

  defp maybe_say_go(false, %{non_dealer: %{active: true} = non_dealer, dealer: dealer} = game) do
    %{
      game
      | non_dealer: %{non_dealer | said_go: true, active: false},
        dealer: %{dealer | active: true}
    }
    |> Notifier.add_notification(:non_dealer, "go")
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

  defp maybe_award_final_go(
         %{
           dealer: %{name: name},
           active_played_cards: [%PlayedCard{played_by: name} | _rest]
         } = game
       ) do
    case hit_thirty_one?(game) do
      true -> game
      false -> ScoreAdder.add_points(game, :dealer, 1, "go")
    end
  end

  defp maybe_award_final_go(
         %{
           non_dealer: %{name: name},
           active_played_cards: [%PlayedCard{played_by: name} | _rest]
         } = game
       ) do
    case hit_thirty_one?(game) do
      true -> game
      false -> ScoreAdder.add_points(game, :non_dealer, 1, "go")
    end
  end

  defp maybe_award_final_go(game), do: game

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

  defp complete_phase(
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
            notifications: [],
            cards: reassign_cards(all_played_cards, dealer_name)
        },
        non_dealer: %{
          non_dealer
          | active: false,
            said_go: false,
            notifications: [],
            cards: reassign_cards(all_played_cards, non_dealer_name)
        },
        active_played_cards: [],
        inactive_played_cards: [],
        phase: Game.next_phase(game)
    }
  end

  defp hit_thirty_one?(game) do
    current_count(game) == 31
  end

  defp reassign_cards(played_cards, name) do
    played_cards
    |> Enum.filter(&(&1.played_by == name))
    |> Enum.map(& &1.card)
    |> Card.sort()
  end
end
