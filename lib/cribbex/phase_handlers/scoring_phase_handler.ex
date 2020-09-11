defmodule Cribbex.ScoringPhaseHandler do
  alias Cribbex.Logic.{
    HandScoring,
    ScoreAdder
  }

  alias Cribbex.Models.Game

  def initiate_scoring_phase(
        %{non_dealer: %{name: name, cards: cards}, flip_card: flip_card} = game_data
      ) do
    score_breakdown = HandScoring.calculate_score(cards, flip_card)

    %{
      game_data
      | scoring_data: %{
          hand: :non_dealer,
          title: "#{name}'s hand",
          cards: cards,
          breakdown: score_breakdown
        }
    }
    |> ScoreAdder.add_points(:non_dealer, score_breakdown.total)
  end

  # was already ready, ignore
  def set_ready(%{dealer: %{name: name, ready: true}} = game_data, name), do: game_data
  def set_ready(%{non_dealer: %{name: name, ready: true}} = game_data, name), do: game_data

  # other player not ready yet
  def set_ready(%{dealer: %{name: name, ready: false} = dealer, non_dealer: %{ready: false}} = game_data, name) do
    %{game_data | dealer: %{dealer | ready: true}}
  end

  def set_ready(%{non_dealer: %{name: name, ready: false} = non_dealer, dealer: %{ready: false}} = game_data, name) do
    %{game_data | non_dealer: %{non_dealer | ready: true}}
  end

  # both players ready
  def set_ready(%{dealer: %{name: name, ready: false}, non_dealer: %{ready: true}} = game_data, name) do
    score_next_hand(game_data)
  end

  def set_ready(%{non_dealer: %{name: name, ready: false}, dealer: %{ready: true}} = game_data, name) do
    score_next_hand(game_data)
  end

  defp score_next_hand(
        %{
          scoring_data: %{hand: :non_dealer},
          dealer: %{name: name, cards: cards} = dealer,
          non_dealer: non_dealer,
          flip_card: flip_card
        } = game_data
      ) do
    score_breakdown = HandScoring.calculate_score(cards, flip_card)

    %{
      game_data
      | scoring_data: %{
          hand: :dealer,
          title: "#{name}'s hand",
          cards: cards,
          breakdown: score_breakdown
        },
        dealer: %{dealer | ready: false},
        non_dealer: %{non_dealer | ready: false}
    }
    |> ScoreAdder.add_points(:dealer, score_breakdown.total)
  end

  defp score_next_hand(
        %{
          scoring_data: %{hand: :dealer},
          dealer: %{name: name} = dealer,
          non_dealer: non_dealer,
          crib: cards,
          flip_card: flip_card
        } = game_data
      ) do
    score_breakdown = HandScoring.calculate_score(cards, flip_card, true)

    %{
      game_data
      | scoring_data: %{
          hand: :crib,
          title: "#{name}'s crib",
          cards: cards,
          breakdown: score_breakdown
        },
        dealer: %{dealer | ready: false},
        non_dealer: %{non_dealer | ready: false}
    }
    |> ScoreAdder.add_points(:dealer, score_breakdown.total)
  end

  defp score_next_hand(%{scoring_data: %{hand: :crib}} = game_data) do
    complete_phase(game_data)
  end

  defp complete_phase(
        %{
          dealer: %{cards: dealer_cards} = dealer,
          non_dealer: %{cards: non_dealer_cards} = non_dealer,
          crib: crib,
          flip_card: flip_card,
          deck: deck
        } = game_data
      ) do
    %{
      game_data
      | crib: [],
        flip_card: nil,
        dealer: %{dealer | cards: [], ready: false},
        non_dealer: %{non_dealer | cards: [], ready: false},
        deck: deck ++ dealer_cards ++ non_dealer_cards ++ crib ++ [flip_card],
        scoring_data: %{},
        phase: Game.next_phase(game_data)
    }
    |> Game.start_hand()
  end
end
