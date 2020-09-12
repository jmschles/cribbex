defmodule Cribbex.Models.Notification do
  defstruct [:source, :points, :text]

  def build(source, points) do
    %__MODULE__{
      source: source,
      points: points,
      text: text(source, points)
    }
  end

  defp text(source, nil), do: source
  defp text(source, points), do: "#{points} for #{source}"
end
