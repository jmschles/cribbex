defmodule CribbexWeb.LandingLive do
  use CribbexWeb, :live_view

  @lobby_topic "lobby"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "", status: :signin, players: [])}
  end

  @impl true
  def handle_event("login", %{"name" => name}, socket) do
    case validate(name) do
      true ->
        login(socket, name)

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid name")
         |> assign(name: name)}
    end
  end

  def handle_event("invitation:" <> event, payload, socket) do
    CribbexWeb.InvitationHandler.handle_event(event, payload, socket)
  end

  def handle_event("back-to-lobby", _params, socket) do
    {:noreply, assign(socket, status: :idle)}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{name: name, players: players}} = socket
      ) do
    arrivals = Map.keys(joins) |> Enum.reject(&(&1 == name))
    departures = Map.keys(leaves) |> Enum.reject(&(&1 == name))
    updated_player_list = ((players ++ arrivals) -- departures) |> Enum.sort()
    {:noreply, assign(socket, :players, updated_player_list)}
  end

  def handle_info(%{event: "invitation:" <> event, payload: payload}, socket) do
    CribbexWeb.InvitationHandler.handle_info(event, payload, socket)
  end

  # alphanumeric probably... or maybe gen ids so it doesn't matter?
  # also needs to check for duplicate names...
  def validate(_name), do: true

  # helpers

  defp login(socket, name) do
    CribbexWeb.Endpoint.subscribe(@lobby_topic)
    Cribbex.Presence.track(self(), @lobby_topic, name, %{})
    players = Cribbex.Presence.list(@lobby_topic) |> Map.keys()
    CribbexWeb.Endpoint.subscribe("player:#{name}")
    {:noreply, assign(socket, name: name, status: :idle, players: players, invitations: [])}
  end
end
