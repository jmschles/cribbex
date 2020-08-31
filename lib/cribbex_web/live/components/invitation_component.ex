defmodule CribbexWeb.InvitationComponent do
  use CribbexWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="phx-hero">
      <h3>Invitation(s) received</h3>
      <%= if Enum.empty?(@invitations) do %>
        No pending invitations. Invite someone to play!
      <% else %>
        <ul>
          <%= for inviter <- @invitations do %>
            <li>
              <%= inviter %>
              | <a href="#" phx-click="invitation:accept" phx-value-from="<%= inviter %>">Accept</a>
              | <a href="#" phx-click="invitation:decline" phx-value-from="<%= inviter %>">Decline</a>
            </li>
          <% end %>
        </ul>
      <% end %>
    </section>
    """
  end
end