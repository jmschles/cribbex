defmodule Cribbex.PlayerServer do
  use GenServer
  require Logger

  # TODO: implement an idle timeout (need something that will reset the timer when action is taken)

  def start_link(name) do
    registration = {:via, Registry, {Registry.Players, name}}
    GenServer.start_link(__MODULE__, name, name: registration)
  end

  @impl true
  def init(name) do
    {:ok, %{name: name, status: :idle}}
  end

  def handle_info(:goodbye, %{name: name} = state) do
    Logger.info("#{name} has left the building")
    {:stop, :normal, state}
  end
end
