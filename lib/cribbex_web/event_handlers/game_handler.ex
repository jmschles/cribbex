defmodule CribbexWeb.GameHandler do
  import Phoenix.LiveView.Utils, only: [assign: 3]

  alias Cribbex.GameSupervisor

  def handle_event("start", %{"game-id" => game_id}, socket) do
    updated_state = GameSupervisor.start_game(game_id)
    broadcast_state_update(updated_state)
    {:noreply, assign(socket, :game_data, updated_state)}
  end

  def handle_info("state_update", updated_game_data, socket) do
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def broadcast_state_update(%{id: game_id} = game_data) do
    CribbexWeb.Endpoint.broadcast_from(self(), "game:#{game_id}", "game:state_update", game_data)
  end
end
