defmodule Cribbex.Models.Notification do
  defstruct [:id, :player_name, :reason, :points, :text]

  def build(player_name: player_name, reason: reason, points: points) do
    %__MODULE__{
      id: Cribbex.Helpers.random_alpha_id(),
      player_name: player_name,
      reason: reason,
      points: points,
      text: "#{points} for #{reason}"
    }
  end
end
