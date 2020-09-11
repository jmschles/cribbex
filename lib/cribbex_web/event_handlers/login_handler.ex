defmodule CribbexWeb.LoginHandler do
  import Phoenix.LiveView.Utils, only: [put_flash: 3, assign: 3, clear_flash: 1]

  def handle_login(%{"name" => name}, socket) do
    case Cribbex.NameValidator.validate(name) do
      :ok ->
        login(socket, name)

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, error)
         |> assign(:name, name)}
    end
  end

  # helpers

  @lobby_topic "lobby"
  defp login(socket, name) do
    CribbexWeb.Endpoint.subscribe(@lobby_topic)
    Cribbex.Presence.track(self(), @lobby_topic, name, %{topic: @lobby_topic})
    players = Cribbex.Presence.list(@lobby_topic) |> Map.keys()
    CribbexWeb.Endpoint.subscribe("player:#{name}")

    {:noreply,
     socket
     |> clear_flash()
     |> assign(:name, name)
     |> assign(:messages, [])
     |> assign(:status, :idle)
     |> assign(:players, players)
     |> assign(:invitations, [])}
  end

  def lobby_topic, do: @lobby_topic
end
