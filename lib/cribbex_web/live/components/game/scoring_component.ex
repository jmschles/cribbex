defmodule CribbexWeb.Game.ScoringComponent do
  use CribbexWeb, :live_component

  def button_class(%{ready: true}), do: "active"
  def button_class(%{ready: false}), do: "disabled"
end
