defmodule CribbexWeb.GameHandler do
  import Phoenix.LiveView.Utils, only: [assign: 3]

  alias Cribbex.GameSupervisor

  def handle_event("start", %{"game-id" => game_id}, socket) do
    updated_game_data = GameSupervisor.perform_action(:start_game, game_id)
    broadcast_state_update(updated_game_data)
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_event(
        "discard",
        %{"card-code" => card_code, "game-id" => game_id},
        %{assigns: %{name: name}} = socket
      ) do
    updated_game_data =
      GameSupervisor.perform_action(:discard, game_id, %{card_code: card_code, name: name})

    broadcast_state_update(updated_game_data)
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_event(
        "play-card",
        %{"card-code" => card_code, "game-id" => game_id},
        %{assigns: %{name: name}} = socket
      ) do
    updated_game_data =
      GameSupervisor.perform_action(:play_card, game_id, %{
        card_code: card_code,
        name: name,
        live_pid: self()
      })

    broadcast_state_update(updated_game_data)
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_event("ready", %{"game-id" => game_id}, %{assigns: %{name: name}} = socket) do
    updated_game_data = GameSupervisor.perform_action(:ready, game_id, %{name: name})

    broadcast_state_update(updated_game_data)
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_info(
        "state_update",
        %{dealer: %{name: name, active: true}, phase: :pegging} = updated_game_data,
        %{assigns: %{name: name}} = socket
      ) do
    send(self(), "game:check_for_go")
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_info(
        "state_update",
        %{non_dealer: %{name: name, active: true}, phase: :pegging} = updated_game_data,
        %{assigns: %{name: name}} = socket
      ) do
    send(self(), "game:check_for_go")
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_info("state_update", updated_game_data, socket) do
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_info("check_for_go", %{assigns: %{game_data: %{id: game_id}}} = socket) do
    case GameSupervisor.perform_action(:check_for_go, game_id, %{live_pid: self()}) do
      :noop ->
        {:noreply, socket}

      updated_game_data ->
        broadcast_state_update(updated_game_data)
        {:noreply, assign(socket, :game_data, updated_game_data)}
    end
  end

  def handle_info(action, %{assigns: %{game_data: %{id: game_id}}} = socket)
      when action in ~w[go_followup thirty_one_reset complete_pegging_phase] do
    updated_game_data = GameSupervisor.perform_action(String.to_atom(action), game_id)
    broadcast_state_update(updated_game_data)
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def broadcast_state_update(%{id: game_id} = game_data) do
    CribbexWeb.Endpoint.broadcast_from(self(), "game:#{game_id}", "game:state_update", game_data)
  end
end
