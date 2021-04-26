defmodule Cribbex.Recovery do
  def recover_game_id_for(player_name) do
    DynamicSupervisor.which_children(Cribbex.GameSupervisor)
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&GenServer.call(&1, :state))
    |> Enum.find(& player_name in &1.player_names)
    |> case do
      %{id: id} -> id
      _ -> nil
    end
  end
end
