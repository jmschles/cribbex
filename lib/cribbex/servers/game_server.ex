defmodule Cribbex.GameServer do
  use GenServer
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
    updated_state = Game.start_hand(game_state)
    {:reply, updated_state, updated_state}
  end

  def handle_call({:discard, card_code, name}, _from, game_state) do
    updated_state = Game.handle_discard(game_state, card_code, name)
    {:reply, updated_state, updated_state}
  end

  def handle_call({:play_card, card_code, name}, _from, game_state) do
    updated_state = Game.handle_play(game_state, card_code, name)
    {:reply, updated_state, updated_state}
  end

  def handle_call({:check_for_go, live_pid}, _from, game_state) do
    case Game.handle_go_check(game_state, live_pid) do
      :noop -> {:reply, :noop, game_state}
      updated_game_state ->  {:reply, updated_game_state, updated_game_state}
    end
  end

  def handle_call(:go_followup, _from, game_state) do
    updated_state = Game.handle_go_followup(game_state)
    {:reply, updated_state, updated_state}
  end

  def handle_call({:ready, name}, _from, game_state) do
    updated_state = Game.set_ready(game_state, name)
    {:reply, updated_state, updated_state}
  end
end
