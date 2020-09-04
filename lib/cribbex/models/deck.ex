defmodule Cribbex.Models.Deck do
  alias Cribbex.Models.Card

  def build do
    Enum.flat_map(Card.suits(), fn suit ->
      Enum.map(Card.types(), fn type ->
        Card.build(type, suit)
      end)
    end)
    |> Enum.shuffle()
  end
end
