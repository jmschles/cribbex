defmodule Cribbex.GameSupervisor do
  use DynamicSupervisor
  require Logger

  alias Cribbex.Models.Game

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(initial_game_state) do
    spec = {Cribbex.GameServer, initial_game_state}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def initialize_game(players, test \\ false) do
    initial_game_data = Game.build(players, test)
    start_child(initial_game_data)
    {:ok, initial_game_data}
  end

  def perform_action(action, game_id) do
    find_game(game_id)
    |> do_action(action)
  end

  def perform_action(action, game_id, data) do
    find_game(game_id)
    |> do_action(action, data)
  end

  def do_action(game_pid, :start_game) do
    GenServer.call(game_pid, :new_hand)
  end

  def do_action(game_pid, :get_game_state) do
    GenServer.call(game_pid, :state)
  end

  def do_action(game_pid, :check_for_go) do
    GenServer.call(game_pid, :check_for_go)
  end

  def do_action(game_pid, :discard, %{card_code: card_code, name: name}) do
    GenServer.call(game_pid, {:discard, card_code, name})
  end

  def do_action(game_pid, :play_card, %{card_code: card_code, name: name}) do
    GenServer.call(game_pid, {:play_card, card_code, name})
  end

  def do_action(game_pid, :ready, %{name: name}) do
    GenServer.call(game_pid, {:ready, name})
  end

  def find_game(id, tries \\ 10) do
    try_game_find(id, tries)
  end

  # TODO: it'd be slightly (but not much) friendlier to find a way to
  # send players back to the lobby if the game's gone missing
  defp try_game_find(_id, 0), do: raise("Game not found")

  defp try_game_find(id, tries) do
    with [{pid, _}] <- Registry.lookup(Registry.Games, id) do
      pid
    else
      _ ->
        Logger.warn("retrying game find, attempt #{11 - tries}")
        :timer.sleep(200)
        try_game_find(id, tries - 1)
    end
  end
end
