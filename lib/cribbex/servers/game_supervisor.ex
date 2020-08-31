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

  def initialize_game(players) do
    initial_game_data = Game.build(players)
    start_child(initial_game_data)
    {:ok, initial_game_data}
  end

  def get_game_state_by_id(id, retries \\ 10) do
    try_game_find(id, retries)
    |> GenServer.call(:state)
  end

  def try_game_find(_id, 0), do: raise "Game not found"

  def try_game_find(id, retries) do
    with [{pid, _}] <- Registry.lookup(Registry.Games, id) do
      pid
    else
      _ ->
        Logger.warn("retrying game find, attempt #{11 - retries}")
        :timer.sleep(200)
        try_game_find(id, retries - 1)
    end
  end
end
