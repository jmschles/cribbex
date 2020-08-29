defmodule CribbexWeb.LandingComponent do
  use CribbexWeb, :live_component

  def render(assigns) do
    ~L"""
    <section class="phx-hero">
      <h1>Welcome to Cribbex!</h1>
      <p>Cribbage in Elixir! Maybe this time I'll actually finish it.</p>

      <form phx-submit="submit">
        <input type="text" name="name" value="<%= @name %>" placeholder="Enter your name!" autocomplete="off"/>
        <button type="submit">Go to lobby</button>
      </form>
    </section>
    """
  end
end
