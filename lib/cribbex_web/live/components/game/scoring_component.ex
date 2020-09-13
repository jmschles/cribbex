defmodule CribbexWeb.Game.ScoringComponent do
  use CribbexWeb, :live_component

  def button_class(%{ready: true}), do: "disabled"
  def button_class(%{ready: false}), do: "active"
end
