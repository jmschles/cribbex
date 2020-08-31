defmodule Cribbex.Helpers do
  # Placeholder that obviously needs to be fixed because it's dynamically creating atoms...
  # Alternative would be to rotate through a finite list of words, no game lasts forever
  @chars "abcdefghijklmnopqrstuvwxyz"
  def random_alpha_id do
    alphabet = String.split(@chars, "", trim: true)

    1..12
    |> Enum.reduce([], fn _, acc -> [Enum.random(alphabet) | acc] end)
    |> Enum.join("")
    |> String.to_atom()
  end
end
