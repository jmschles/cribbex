defmodule CribbexWeb.GameComponent do
  use CribbexWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="phx-hero">
      <h1>Oi <%= @name %>, someday you can play a game!</h1>
    </section>
    <section class="phx-hero">
      <h3>Game data:</h3>
      <%= inspect(@game_data) %>
    </section>
    <section class="phx-hero">
      <button class="button-danger" phx-click="back-to-lobby">Back to lobby</button>
    </section>
    """
  end
end
