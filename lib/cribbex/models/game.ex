defmodule Cribbex.Models.Game do
  alias Cribbex.Models.Deck
  alias Cribbex.Helpers

  defdelegate deal(game), to: Cribbex.DiscardPhaseHandler
  defdelegate set_dealer(game), to: Cribbex.DiscardPhaseHandler
  defdelegate handle_discard(game, card_code, name), to: Cribbex.DiscardPhaseHandler

  @phases [
    :discard,
    :pegging,
    :scoring
  ]

  defstruct([
    :id,
    :dealer,
    :non_dealer,
    :flip_card,
    deck: Deck.build(),
    phase: :pregame,
    played_cards: [],
    player_names: [],
    crib: []
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
