defmodule CribbexWeb.LandingLive do
  use CribbexWeb, :live_view

  @impl true
  # TESTING
  def mount(_params, _session, socket) do
    {:ok, Cribbex.Helpers.discard_phase_test(socket)}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, status: :signin)}
  end

  @impl true
  def handle_event("login", payload, socket) do
    CribbexWeb.LoginHandler.handle_login(payload, socket)
  end

  def handle_event("invitation:" <> event, payload, socket) do
    CribbexWeb.InvitationHandler.handle_event(event, payload, socket)
  end

  def handle_event("game:" <> event, payload, socket) do
    CribbexWeb.GameHandler.handle_event(event, payload, socket)
  end

  # TODO: decide what to do with this
  def handle_event("back-to-lobby", _params, socket) do
    {:noreply, assign(socket, status: :idle)}
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
end
