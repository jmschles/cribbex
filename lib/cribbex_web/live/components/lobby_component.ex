defmodule CribbexWeb.LobbyComponent do
  use CribbexWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="phx-hero">
      <h1>O heeeey <%= @name %></h1>
    </section>
    """
  end
end
