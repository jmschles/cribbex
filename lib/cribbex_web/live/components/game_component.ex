defmodule CribbexWeb.GameComponent do
  use CribbexWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="phx-hero">
      <h1>Oi <%= @name %>, someday you can play a game!</h1>
    </section>
    <section class="phx-hero">
      <%= case @game_data.phase do %>
        <%= :pregame -> %>
          <%= live_component @socket, CribbexWeb.Game.PregameComponent, game_id: @game_data.id %>
        <%= :discard -> %>
          <%= live_component @socket, CribbexWeb.Game.DiscardComponent, game_data: @game_data %>
      <% end %>
    </section>
    <section class="phx-hero">
      <button class="button-danger" phx-click="back-to-lobby">Back to lobby</button>
    </section>
    """
  end
end
