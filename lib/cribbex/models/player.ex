defmodule Cribbex.Models.Player do
  defstruct [:name, score: 0, previous_score: 0, action_needed: false, cards: []]
end
