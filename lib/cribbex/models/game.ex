defmodule Cribbex.Models.Game do
  alias Cribbex.Models.Deck

  defdelegate deal(game), to: Cribbex.DiscardPhaseHandler

  @phases [
    :discard,
    :pegging,
    :scoring
  ]

  defstruct([
    :dealer,
    :non_dealer,
    deck: Deck.build(),
    phase: :pregame,
    player_names: []
  ])

  def next_phase(%{phase: :pregame}), do: List.first(@phases)

  def next_phase(%{phase: current_phase}) do
    current_pos = Enum.find_index(@phases, &(&1 == current_phase))
    Enum.at(@phases, current_pos + 1) || List.first(@phases)
  end
end
