defmodule CribbexWeb.Game.PlayerCardsComponent do
  use CribbexWeb, :live_component

  def click_action(:discard), do: "discard"
  def click_action(:pegging), do: "play-card"
  def click_action(_), do: "noop"
end
