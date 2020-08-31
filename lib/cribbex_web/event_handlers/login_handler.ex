defmodule CribbexWeb.LoginHandler do
  import Phoenix.LiveView.Utils, only: [put_flash: 3, assign: 3]

  def handle_login(%{"name" => name}, socket) do
    case validate(name) do
      true ->
        login(socket, name)

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid name")
         |> assign(:name, name)}
    end
  end

  def handle_presence_diff(
        %{joins: joins, leaves: leaves},
        %{assigns: %{name: name, players: players}} = socket
      ) do
    arrivals = Map.keys(joins) |> Enum.reject(&(&1 == name))
    departures = Map.keys(leaves) |> Enum.reject(&(&1 == name))
    updated_player_list = ((players ++ arrivals) -- departures) |> Enum.sort()
    {:noreply, assign(socket, :players, updated_player_list)}
  end

  # helpers

  # alphanumeric probably... or maybe gen ids so it doesn't matter?
  # also needs to check for duplicate names...
  defp validate(_name), do: true

  @lobby_topic "lobby"
  defp login(socket, name) do
    CribbexWeb.Endpoint.subscribe(@lobby_topic)
    Cribbex.Presence.track(self(), @lobby_topic, name, %{})
    players = Cribbex.Presence.list(@lobby_topic) |> Map.keys()
    CribbexWeb.Endpoint.subscribe("player:#{name}")

    {:noreply,
     socket
     |> assign(:name, name)
     |> assign(:status, :idle)
     |> assign(:players, players)
     |> assign(:invitations, [])}
  end
end
