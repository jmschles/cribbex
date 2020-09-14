defmodule Cribbex.Helpers do
  import Phoenix.LiveView.Utils, only: [assign: 3]

  @chars "abcdefghijklmnopqrstuvwxyz"
  def random_alpha_id do
    alphabet = String.split(@chars, "", trim: true)

    1..8
    |> Enum.reduce([], fn _, acc -> [Enum.random(alphabet) | acc] end)
    |> Enum.join("")
  end

  def subscribe_to_game(socket, game_id, name) do
    topic = game_topic(game_id)

    CribbexWeb.Endpoint.subscribe(topic)
    Cribbex.Presence.track(self(), topic, name, %{topic: topic})

    socket
  end

  def unsubscribe_from_game(socket, game_id, name) do
    topic = game_topic(game_id)

    CribbexWeb.Endpoint.unsubscribe(topic)
    Cribbex.Presence.untrack(self(), topic, name)

    socket
  end

  @lobby_topic "lobby"
  def subscribe_to_lobby(socket, name) do
    CribbexWeb.Endpoint.subscribe(@lobby_topic)
    Cribbex.Presence.track(self(), @lobby_topic, name, %{topic: @lobby_topic})
    players = Cribbex.Presence.list(@lobby_topic) |> Map.keys()
    CribbexWeb.Endpoint.subscribe("player:#{name}")

    assign(socket, :players, players)
  end

  def unsubscribe_from_lobby(socket, name) do
    CribbexWeb.Endpoint.unsubscribe(@lobby_topic)
    Cribbex.Presence.untrack(self(), @lobby_topic, name)

    socket
  end

  defp game_topic(game_id), do: "game:" <> game_id

  ### for fast testing: load in with a live game state ###

  # alias Cribbex.Models.Game
  import Phoenix.LiveView.Utils, only: [assign: 3]
  require Logger

  def discard_phase_test(socket) do
    name = pick_name()
    CribbexWeb.Endpoint.subscribe("lobby")
    Cribbex.Presence.track(self(), "lobby", name, %{topic: "lobby"})
    game = find_or_initialize_game()

    socket
    |> assign(:status, :in_game)
    |> assign(:name, name)
    |> subscribe(game.id)
    |> assign(:game_data, game)
    |> assign(:messages, [])
    |> sleep()
    |> maybe_start_game()
  end

  defp find_or_initialize_game do
    try do
      pid = Cribbex.GameSupervisor.find_game("test", 5)
      Cribbex.GameSupervisor.do_action(pid, :get_game_state)
    rescue
      error ->
        IO.inspect(error)
        {:ok, game_data} = Cribbex.GameSupervisor.initialize_game(["frog", "toad"], true)
        game_data
    end
  end

  def sleep(socket) do
    :timer.sleep(300)
    socket
  end

  defp pick_name do
    case Cribbex.Presence.list("lobby") |> Map.keys() do
      [] -> "frog"
      _ -> "toad"
    end
  end

  defp maybe_start_game(%{assigns: %{name: "toad", game_data: %{phase: :pregame}}} = socket) do
    Logger.warn("Starting game")

    {:noreply, socket} =
      CribbexWeb.GameHandler.handle_event("start", %{"game-id" => "test"}, socket)

    socket
  end

  defp maybe_start_game(socket), do: socket

  defp subscribe(%{assigns: %{name: me}} = socket, game_id) do
    subscribe_to_game(socket, game_id, me)
  end
end
