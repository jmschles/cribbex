defmodule Cribbex.Models.Game do
  alias Cribbex.Models.Deck
  alias Cribbex.Helpers

  defdelegate start_hand(game), to: Cribbex.DiscardPhaseHandler
  defdelegate handle_discard(game, card_code, name), to: Cribbex.DiscardPhaseHandler

  defdelegate handle_play(game, card_code, name, live_pid), to: Cribbex.PeggingPhaseHandler
  defdelegate handle_go_check(game, live_pid), to: Cribbex.PeggingPhaseHandler
  defdelegate handle_go_followup(game), to: Cribbex.PeggingPhaseHandler
  defdelegate handle_thirty_one_reset(game), to: Cribbex.PeggingPhaseHandler
  defdelegate handle_complete_pegging_phase(game), to: Cribbex.PeggingPhaseHandler

  defdelegate initiate_scoring_phase(game), to: Cribbex.ScoringPhaseHandler
  defdelegate set_ready(game, name), to: Cribbex.ScoringPhaseHandler

  @phases [
    :discard,
    :pegging,
    :scoring
  ]

  defstruct([
    :id,
    :dealer,
    :error,
    :non_dealer,
    :flip_card,
    :winner,
    game_ending: false,
    pegging_tally: 0,
    deck: Deck.build(),
    scoring_data: %{},
    phase: :pregame,
    active_played_cards: [],
    inactive_played_cards: [],
    player_names: [],
    crib: [],
    notifications: []
  ])

  def build(players, test) do
    id = if test, do: "test", else: Helpers.random_alpha_id()

    %__MODULE__{
      id: id,
      player_names: players
    }
  end

  def next_phase(%{phase: :pregame}), do: List.first(@phases)

  def next_phase(%{phase: current_phase}) do
    current_pos = Enum.find_index(@phases, &(&1 == current_phase))
    Enum.at(@phases, current_pos + 1) || List.first(@phases)
  end
end
