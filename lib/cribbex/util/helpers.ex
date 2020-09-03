defmodule Cribbex.Helpers do
  @chars "abcdefghijklmnopqrstuvwxyz"
  def random_alpha_id do
    alphabet = String.split(@chars, "", trim: true)

    1..12
    |> Enum.reduce([], fn _, acc -> [Enum.random(alphabet) | acc] end)
    |> Enum.join("")
  end
end
