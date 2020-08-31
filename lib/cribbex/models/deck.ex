defmodule Cribbex.Models.Deck do
  alias Cribbex.Models.Card

  defstruct [:flip_card, cards: []]

  def build do
    %__MODULE__{
      cards:
        Enum.flat_map(Card.suits(), fn suit ->
          Enum.map(Card.types(), fn type ->
            Card.build(type, suit)
          end)
        end)
        |> Enum.shuffle()
    }
  end
end
