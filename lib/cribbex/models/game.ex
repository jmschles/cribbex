defmodule Cribbex.Models.Game do
  alias Cribbex.Models.Deck
  alias Cribbex.Helpers

  defdelegate deal(game), to: Cribbex.DiscardPhaseHandler

  @phases [
    :discard,
    :pegging,
    :scoring
  ]

  defstruct([
    :id,
    :dealer,
    :non_dealer,
    deck: Deck.build(),
    phase: :pregame,
    player_names: []
  ])

  def build(players) do
    %__MODULE__{
      id: Helpers.random_alpha_id(),
      player_names: players
    }
  end

  def next_phase(%{phase: :pregame}), do: List.first(@phases)

  def next_phase(%{phase: current_phase}) do
    current_pos = Enum.find_index(@phases, &(&1 == current_phase))
    Enum.at(@phases, current_pos + 1) || List.first(@phases)
  end
end
