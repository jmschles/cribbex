defmodule Cribbex.Helpers do
  @chars "abcdefghijklmnopqrstuvwxyz"
  def random_alpha_id do
    alphabet = String.split(@chars, "", trim: true)

    1..12
    |> Enum.reduce([], fn _, acc -> [Enum.random(alphabet) | acc] end)
    |> Enum.join("")
  end


  ### for fast testing: load in with a live game state

  alias Cribbex.Models.Game
  import Phoenix.LiveView.Utils, only: [assign: 3]

  def discard_phase_test(socket) do
    name = pick_name()
    CribbexWeb.Endpoint.subscribe("lobby")
    Cribbex.Presence.track(self(), "lobby", name, %{topic: "lobby"})
    game = find_or_initialize_game()

    socket
    |> assign(:status, :in_game)
    |> assign(:name, name)
    |> subscribe_to_game(game.id)
    |> assign(:game_data, game)
    |> sleep()
    |> maybe_start_game()
  end

  defp find_or_initialize_game do
    try do
      pid = Cribbex.GameSupervisor.find_game("test", 1)
      {:ok, game_state} = Cribbex.GameSupervisor.do_action(pid, :get_game_state)
      game_state
    rescue
      _error ->
        {:ok, game_data} = Cribbex.GameSupervisor.initialize_game(["frog", "toad"], true)
        game_data
    end
  end

  def sleep(socket) do
    :timer.sleep(1000)
    socket
  end

  defp pick_name do
    case Cribbex.Presence.list("lobby") |> Map.keys() do
      [] -> "frog"
      _ -> "toad"
    end
  end

  defp maybe_start_game(socket) do
    case Cribbex.Presence.list("game:test") |> Map.keys() |> length() |> IO.inspect(label: "fuck") do
      2 ->
        case socket.assigns.name do
          "toad" ->
            {:noreply, socket} = CribbexWeb.GameHandler.handle_event("start", %{"game-id" => "test"}, socket)
            socket

          _ ->
            socket
        end

      _ -> socket
    end
  end

  defp subscribe_to_game(%{assigns: %{name: me}} = socket, game_id) do
    topic = "game:" <> game_id
    IO.inspect(me, label: "NAME")
    IO.inspect(self(), label: "PID")

    CribbexWeb.Endpoint.subscribe(topic)
    Cribbex.Presence.track(self(), topic, me, %{topic: topic})

    socket
  end
end
