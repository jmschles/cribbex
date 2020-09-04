defmodule CribbexWeb.GameHandler do
  import Phoenix.LiveView.Utils, only: [assign: 3]

  alias Cribbex.GameSupervisor

  def handle_event("start", %{"game-id" => game_id}, socket) do
    updated_game_data = GameSupervisor.perform_action(:start_game, game_id)
    broadcast_state_update(updated_game_data)
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_event("discard", %{"card-code" => card_code, "game-id" => game_id}, %{assigns: %{name: name}} = socket) do
    updated_game_data = GameSupervisor.perform_action(:discard, game_id, %{card_code: card_code, name: name})
    broadcast_state_update(updated_game_data)
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_info("state_update", updated_game_data, socket) do
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def broadcast_state_update(%{id: game_id} = game_data) do
    CribbexWeb.Endpoint.broadcast_from(self(), "game:#{game_id}", "game:state_update", game_data)
  end
end
