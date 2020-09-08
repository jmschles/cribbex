defmodule Cribbex.Models.Player do
  defstruct [:name, score: 0, previous_score: 0, active: false, said_go: false, cards: [], notifications: []]
end
