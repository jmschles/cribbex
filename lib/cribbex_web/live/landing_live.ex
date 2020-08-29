defmodule CribbexWeb.LandingLive do
  use CribbexWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "")}
  end

  @impl true
  def handle_event("submit", %{"name" => name}, socket) do
    case validate(name) do
      true ->
        Cribbex.PlayerManager.add_player(name)
        {:noreply, assign(socket, name: name)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Sorry, please choose a valid name")
         |> assign(name: name)}
    end
  end

  # alphanumeric probably
  def validate(name), do: true
end
