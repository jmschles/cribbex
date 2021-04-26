defmodule CribbexWeb.LandingLive do
  use CribbexWeb, :live_view

  @impl true
  # TESTING
  # def mount(_params, _session, socket) do
  #   {:ok, Cribbex.Helpers.discard_phase_test(socket)}
  # end

  def mount(_params, %{"name" => name}, socket) do
    {:noreply, socket} = CribbexWeb.LoginHandler.handle_login(%{"name" => name}, socket)

    case Cribbex.Recovery.recover_game_id_for(name) do
      nil ->
        {:ok, socket}

      game_id ->
        game_data = Cribbex.GameSupervisor.perform_action(:get_game_state, game_id)
        {:ok, CribbexWeb.InvitationHandler.game_start_pipeline(socket, game_data)}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, status: :signin)}
  end

  @impl true
  def handle_event("login", payload, socket) do
    CribbexWeb.LoginHandler.handle_login(payload, socket)
  end

  def handle_event("logout", _payload, socket) do
    CribbexWeb.LoginHandler.handle_logout(socket)
  end

  def handle_event("invitation:" <> event, payload, socket) do
    CribbexWeb.InvitationHandler.handle_event(event, payload, socket)
  end

  def handle_event("game:" <> event, payload, socket) do
    CribbexWeb.GameHandler.handle_event(event, payload, socket)
  end

  def handle_event("chat:" <> event, payload, socket) do
    CribbexWeb.ChatHandler.handle_event(event, payload, socket)
  end

  @impl true
  def handle_info(%{event: "invitation:" <> event, payload: payload}, socket) do
    CribbexWeb.InvitationHandler.handle_info(event, payload, socket)
  end

  def handle_info(%{event: "presence_" <> event, payload: payload}, socket) do
    CribbexWeb.PresenceHandler.handle_info(event, payload, socket)
  end

  def handle_info(%{event: "game:" <> event, payload: payload}, socket) do
    CribbexWeb.GameHandler.handle_info(event, payload, socket)
  end

  def handle_info("game:" <> event, socket) do
    CribbexWeb.GameHandler.handle_info(event, socket)
  end

  def handle_info(%{event: "chat:" <> event, payload: payload}, socket) do
    CribbexWeb.ChatHandler.handle_info(event, payload, socket)
  end
end
