defmodule CribbexWeb.LandingLive do
  use CribbexWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    CribbexWeb.Endpoint.subscribe("chat:lobby")
    {:ok, assign(socket, name: "", status: :signin, players: [])}
  end

  @impl true
  def handle_event("submit", %{"name" => name}, socket) do
    case validate(name) do
      true ->
        players = Cribbex.PlayerManager.add_player(name)
        CribbexWeb.Endpoint.broadcast_from(self(), "chat:lobby", "players:update", %{players: players})
        {:noreply, assign(socket, name: name, status: :idle, players: players)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Sorry, please choose a valid name")
         |> assign(name: name)}
    end
  end

  def handle_event("start-game", _params, socket) do
    # initialize a game, give it an id, and subscribe to a topic
    {:noreply, assign(socket, status: :in_game, game_data: %{great: "data"})}
  end

  def handle_event("back-to-lobby", _params, socket) do
    {:noreply, assign(socket, status: :idle)}
  end

  @impl true
  def handle_info(%{event: "players:update", payload: %{players: players}}, socket) do
    {:noreply, assign(socket, :players, players)}
  end

  # alphanumeric probably... or maybe gen ids so it doesn't matter?
  def validate(_name), do: true
end
