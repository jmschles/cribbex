defmodule CribbexWeb.Game.PregameComponent do
  use CribbexWeb, :live_component

  def render(assigns) do
    ~L"""
    <button phx-click="game:start" phx-value-game-id="<%= @game_id %>">Start game!</buton>
    """
  end
end
