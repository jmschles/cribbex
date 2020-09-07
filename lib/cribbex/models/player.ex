defmodule Cribbex.Models.Player do
  defstruct [:name, score: 0, previous_score: 0, active: false, cards: [], notifications: []]
end
