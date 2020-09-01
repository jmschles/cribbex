defmodule Cribbex.GameServer do
  use GenServer
  require Logger
  alias Cribbex.Models.Game

  # TODO: implement an idle timeout

  def start_link(initial_game_state) do
    registration = {:via, Registry, {Registry.Games, initial_game_state.id}}
    GenServer.start_link(__MODULE__, initial_game_state, name: registration)
  end

  def state do
    GenServer.call(__MODULE__, :state)
  end

  @impl true
  def init(initial_game_state) do
    {:ok, initial_game_state}
  end

  @impl true
  def handle_call(:state, _from, game_state) do
    {:reply, game_state, game_state}
  end

  def handle_call(:new_hand, _from, game_state) do
    updated_state = game_state |> Game.set_dealer() |> Game.deal()
    {:reply, updated_state, updated_state}
  end
end
