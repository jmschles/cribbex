defmodule CribbexWeb.GameHandler do
  import Phoenix.LiveView.Utils, only: [assign: 3, put_flash: 3]

  alias Cribbex.{
    GameSupervisor,
    Helpers
  }

  def handle_event(event, _payload, %{assigns: %{game_data: %{game_ending: true}}} = socket)
      when event not in ~w[game_over boot_to_lobby] do
    {:noreply, socket}
  end

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

  # handle_info/3

  def handle_info(event, _payload, %{assigns: %{game_data: %{game_ending: true}}} = socket)
      when event not in ~w[game_over boot_to_lobby] do
    {:noreply, socket}
  end

  def handle_info("state_update", %{winner: winner, id: game_id} = updated_game_data, socket)
      when not is_nil(winner) do
    CribbexWeb.Endpoint.broadcast("game:" <> game_id, "game:end_game", %{})
    GameSupervisor.kill_game(game_id)
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

  def handle_info("boot_to_lobby", _payload, socket) do
    Process.send_after(self(), "game:boot_to_lobby", 10000)
    {:noreply, socket |> put_flash(:error, "Game timing out due to inactivity")}
  end

  # handle_info/2

  def handle_info("state_update", updated_game_data, socket) do
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_info("end_game", _payload, %{assigns: %{game_data: game_data}} = socket) do
    Process.send_after(self(), "game:game_over", 3000)
    Process.send_after(self(), "game:boot_to_lobby", 10000)
    {:noreply, assign(socket, :game_data, %{game_data | game_ending: true})}
  end

  def handle_info(
        "disconnect",
        %{name: name},
        %{assigns: %{game_data: %{id: game_id, game_ending: false} = game_data}} = socket
      ) do
    GameSupervisor.kill_game(game_id)
    Process.send_after(self(), "game:boot_to_lobby", 10000)

    {:noreply,
     socket
     |> put_flash(:error, "#{name} disconnected, game ending...")
     |> assign(:game_data, %{game_data | game_ending: true})}
  end

  def handle_info("disconnect", _payload, socket), do: {:noreply, socket}

  def handle_info(event, %{assigns: %{game_data: %{game_ending: true}}} = socket)
      when event not in ~w[game_over boot_to_lobby] do
    {:noreply, socket}
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

  def handle_info("game_over", %{assigns: %{game_data: game_data}} = socket) do
    updated_game_data = %{game_data | phase: :over}
    {:noreply, assign(socket, :game_data, updated_game_data)}
  end

  def handle_info("boot_to_lobby", %{assigns: %{name: name, game_data: %{id: game_id}}} = socket) do
    return_to_lobby(socket, name, game_id)
  end

  defp broadcast_state_update(%{id: game_id} = game_data) do
    CribbexWeb.Endpoint.broadcast_from(self(), "game:#{game_id}", "game:state_update", game_data)
  end

  defp return_to_lobby(socket, name, game_id) do
    socket
    |> Helpers.unsubscribe_from_game(game_id, name)
    |> assign(:game_data, nil)
    |> CribbexWeb.LoginHandler.login(name)
  end
end
