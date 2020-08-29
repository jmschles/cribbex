defmodule CribbexWeb.LobbyComponent do
  use CribbexWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="phx-hero">
      <h1>O heeeey <%= @name %></h1>
    </section>
    <section class="phx-hero">
      <h3>Players online</h3>
      <ul>
        <%= for player <- @players do %>
          <li><%= player %></li>
        <% end %>
      </ul>
    </section>
    <section class="phx-hero">
      <button phx-click="start-game">Start game</button>
    </section>
    """
  end
end
