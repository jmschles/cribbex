defmodule CribbexWeb.LandingLive do
  use CribbexWeb, :live_view

  @impl true
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

  def handle_event("back-to-lobby", _params, socket) do
    {:noreply, assign(socket, status: :idle)}
  end

  @impl true
  def handle_info(%{event: "invitation:" <> event, payload: payload}, socket) do
    CribbexWeb.InvitationHandler.handle_info(event, payload, socket)
  end

  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    CribbexWeb.LoginHandler.handle_presence_diff(payload, socket)
  end
end
