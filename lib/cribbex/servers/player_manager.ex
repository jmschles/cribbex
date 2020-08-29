defmodule Cribbex.PlayerManager do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def players do
    GenServer.call(__MODULE__, :players)
  end

  def add_player(name) do
    GenServer.call(__MODULE__, {:add_player, name})
  end

  # hopefully we can invoke this on socket disconnect
  def remove_player(name) do
    GenServer.cast(__MODULE__, {:remove_player, name})
  end

  @impl true
  def init(_arg) do
    {:ok, []}
  end

  @impl true
  def handle_call(:players, _from, players) do
    {:reply, players, players}
  end

  def handle_call({:add_player, name}, _from, players) do
    Cribbex.PlayerSupervisor.start_child(name)
    {:reply, [name | players], [name | players]}
  end

  @impl true
  def handle_cast({:remove_player, name}, players) do
    with [{pid, _}] <- Registry.lookup(Registry.Players, name) do
      send(pid, :goodbye)
    end

    {:noreply, Enum.reject(players, &(&1 == name))}
  end
end
