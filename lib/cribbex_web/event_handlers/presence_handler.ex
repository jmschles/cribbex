defmodule CribbexWeb.PresenceHandler do
  import Phoenix.LiveView.Utils, only: [assign: 3]

  def handle_info("diff", %{joins: joins, leaves: leaves}, socket) do
    Enum.each(joins, fn
      {name, %{metas: [%{topic: topic}]}} ->
        send(self(), %{event: "presence_join", payload: %{player: name, topic: topic}})
    end)

    Enum.each(leaves, fn
      {name, %{metas: [%{topic: topic}]}} ->
        send(self(), %{event: "presence_leave", payload: %{player: name, topic: topic}})
    end)

    {:noreply, socket}
  end

  # ignore my own join/leave events
  def handle_info(_event, %{player: me}, %{assigns: %{name: me}} = socket), do: {:noreply, socket}

  def handle_info(
        "join",
        %{player: joined_player, topic: "lobby"},
        %{assigns: %{players: players}} = socket
      ) do
    {:noreply, assign(socket, :players, [joined_player | players] |> Enum.sort())}
  end

  def handle_info(
        "leave",
        %{player: left_player, topic: "lobby"},
        %{assigns: %{players: players}} = socket
      ) do
    {:noreply, assign(socket, :players, (players -- [left_player]) |> Enum.sort())}
  end

  def handle_info("leave", %{topic: "game:" <> _game_id}, socket) do
    # TODO: someone dipped or disconnected, boot remaining player(s)
    {:noreply, socket}
  end

  # ignore events we don't need to react to
  def handle_info(_event, _payload, socket), do: {:noreply, socket}
end
