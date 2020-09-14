defmodule CribbexWeb.InvitationHandler do
  import Phoenix.LiveView.Utils, only: [put_flash: 3, assign: 3, clear_flash: 1]

  alias Cribbex.Helpers

  def handle_event("sent", %{"to" => invitee}, socket) do
    CribbexWeb.Endpoint.broadcast_from(self(), "player:#{invitee}", "invitation:received", %{
      from: socket.assigns.name
    })

    {:noreply, socket |> put_flash(:info, "Invitation sent to #{invitee}!")}
  end

  def handle_event("accept", %{"from" => inviter}, socket) do
    CribbexWeb.Endpoint.broadcast_from(self(), "player:#{inviter}", "invitation:accepted", %{
      from: socket.assigns.name
    })

    {:noreply, socket}
  end

  def handle_event(
        "decline",
        %{"from" => inviter},
        %{assigns: %{invitations: invitations}} = socket
      ) do
    CribbexWeb.Endpoint.broadcast_from(self(), "player:#{inviter}", "invitation:declined", %{
      from: socket.assigns.name
    })

    {:noreply, assign(socket, :invitations, invitations -- [inviter])}
  end

  def handle_info("received", %{from: inviter}, %{assigns: %{invitations: invitations}} = socket) do
    {:noreply, assign(socket, :invitations, Enum.uniq(invitations ++ [inviter]))}
  end

  def handle_info("accepted", %{from: invitee}, %{assigns: %{status: :idle, name: me}} = socket) do
    {:ok, game_data} = Cribbex.GameSupervisor.initialize_game([me, invitee])

    CribbexWeb.Endpoint.broadcast_from(self(), "player:#{invitee}", "invitation:join-game", %{
      game_id: game_data.id
    })

    {:noreply, game_start_pipeline(socket, game_data)}
  end

  # ignore if we weren't idle, i.e. another invitation was already accepted
  def handle_info("accepted", _payload, socket) do
    {:noreply, socket}
  end

  def handle_info("declined", %{from: invitee}, %{assigns: %{status: :idle}} = socket) do
    {:noreply, socket |> put_flash(:info, "#{invitee} is busy or something")}
  end

  def handle_info("declined", _payload, socket) do
    {:noreply, socket}
  end

  def handle_info("join-game", %{game_id: game_id}, socket) do
    game_data = Cribbex.GameSupervisor.perform_action(:get_game_state, game_id)
    decline_outstanding_invitations(socket)

    {:noreply, game_start_pipeline(socket, game_data)}
  end

  # helpers

  defp game_start_pipeline(socket, %{id: game_id} = game_data) do
    socket
    |> decline_outstanding_invitations()
    |> subscribe_to_game(game_id)
    |> assign(:invitations, [])
    |> assign(:game_data, game_data)
    |> assign(:status, :in_game)
    |> assign(:messages, [])
    |> clear_flash()
  end

  defp decline_outstanding_invitations(%{assigns: %{name: me, invitations: invitations}} = socket) do
    for invitation <- invitations do
      CribbexWeb.Endpoint.broadcast_from(self(), "player:#{invitation}", "invitation:declined", %{
        from: me
      })
    end

    socket
  end

  defp subscribe_to_game(%{assigns: %{name: me}} = socket, game_id) do
    socket
    |> Helpers.unsubscribe_from_lobby(me)
    |> Helpers.subscribe_to_game(game_id, me)
  end
end
