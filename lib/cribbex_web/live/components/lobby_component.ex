defmodule CribbexWeb.LobbyComponent do
  use CribbexWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="phx-hero">
      <h1>O heeeey <%= @name %></h1>
    </section>
    <%= live_component(@socket, CribbexWeb.InvitationComponent, invitations: @invitations) %>
    <section class="phx-hero">
      <h3>Players online</h3>
      <ul>
        <%= for player <- @players do %>
          <li><%= player %>
          <%= if player != @name do %>
            | <a href="#" phx-click="invitation:sent" phx-value-to="<%= player %>">Invite to game</a></li>
          <% end %>
        <% end %>
      </ul>
    </section>
    """
  end
end
