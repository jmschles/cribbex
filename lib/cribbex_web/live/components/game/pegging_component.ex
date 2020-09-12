defmodule CribbexWeb.Game.PeggingComponent do
  use CribbexWeb, :live_component

  def tally(active_played_cards) do
    active_played_cards
    |> Enum.map(& &1.card.value)
    |> Enum.sum()
  end
end
