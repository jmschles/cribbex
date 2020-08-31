defmodule CribbexWeb.LandingLive do
  use CribbexWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    CribbexWeb.Endpoint.subscribe("general")
    {:ok, assign(socket, name: "", status: :signin, players: [])}
  end

  @impl true
  def handle_event("submit", %{"name" => name}, socket) do
    case validate(name) do
      true ->
        players = Cribbex.PlayerManager.add_player(name)
        CribbexWeb.Endpoint.subscribe("player:#{name}")
        CribbexWeb.Endpoint.broadcast_from(self(), "general", "players:update", %{players: players})
        {:noreply, assign(socket, name: name, status: :idle, players: players, invitations: [])}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid name")
         |> assign(name: name)}
    end
  end

  def handle_event("start-game", _params, socket) do
    # initialize a game, give it an id, and subscribe to a topic
    {:noreply, assign(socket, status: :in_game, game_data: %{great: "data"})}
  end

  def handle_event("invitation:sent", %{"to" => invitee}, socket) do
    CribbexWeb.Endpoint.broadcast_from(self(), "player:#{invitee}", "invitation:received", %{from: socket.assigns.name})
    {:noreply, socket |> put_flash(:info, "Invitation sent to #{invitee}!")}
  end

  def handle_event("invitation:accept", %{"from" => inviter}, socket) do
    CribbexWeb.Endpoint.broadcast_from(self(), "player:#{inviter}", "invitation:accepted", %{from: socket.assigns.name})
    {:noreply, socket}
  end

  def handle_event("invitation:decline", %{"from" => inviter}, %{assigns: %{invitations: invitations}} = socket) do
    CribbexWeb.Endpoint.broadcast_from(self(), "player:#{inviter}", "invitation:declined", %{from: socket.assigns.name})
    {:noreply, assign(socket, :invitations, invitations -- [inviter])}
  end

  def handle_event("back-to-lobby", _params, socket) do
    {:noreply, assign(socket, status: :idle)}
  end

  @impl true
  def handle_info(%{event: "players:update", payload: %{players: players}}, socket) do
    {:noreply, assign(socket, :players, players)}
  end

  def handle_info(%{event: "invitation:received", payload: %{from: inviter}}, %{assigns: %{invitations: invitations}} = socket) do
    {:noreply, assign(socket, :invitations, [inviter | invitations])}
  end

  def handle_info(%{event: "invitation:accepted", payload: %{from: invitee}}, %{assigns: %{status: :idle, name: me}} = socket) do
    {:ok, game_data} = Cribbex.GameSupervisor.initialize_game([me, invitee])
    CribbexWeb.Endpoint.broadcast_from(self(), "player:#{invitee}", "game:join", %{game_id: game_data.id})
    decline_outstanding_invitations(socket)
    {:noreply, assign(socket, invitations: [], game_data: game_data, status: :in_game)}
  end

  # ignore if we weren't idle, i.e. another invitation was already accepted
  def handle_info(%{event: "invitation:accepted"}, socket) do
    {:noreply, socket}
  end

  def handle_info(%{event: "invitation:declined", payload: %{from: invitee}}, socket) do
    {:noreply, socket |> put_flash(:info, "#{invitee} is busy or something")}
  end

  def handle_info(%{event: "game:join", payload: %{game_id: id}}, socket) do
    game_data = Cribbex.GameSupervisor.get_game_state_by_id(id)
    decline_outstanding_invitations(socket)
    {:noreply, assign(socket, invitations: [], game_data: game_data, status: :in_game)}
  end

  # alphanumeric probably... or maybe gen ids so it doesn't matter?
  def validate(_name), do: true

  # helpers
  defp decline_outstanding_invitations(%{assigns: %{name: me, invitations: invitations}}) do
    for invitation <- invitations do
      CribbexWeb.Endpoint.broadcast_from(self(), "player:#{invitation}", "invitation:declined", %{from: me})
    end
  end
end
