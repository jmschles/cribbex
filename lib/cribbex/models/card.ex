defmodule Cribbex.Models.Card do
  defstruct [:suit, :type, :value, :run_order, :human_name, :code]

  def build(type, suit) do
    %__MODULE__{
      type: type,
      suit: suit,
      value: value(type),
      run_order: run_order(type),
      human_name: "#{type} of #{suit}",
      code: set_code(type, suit)
    }
  end

  def suits, do: ~w[Spades Hearts Diamonds Clubs]
  def types, do: ~w[2 3 4 5 6 7 8 9 10 Jack Queen King Ace]

  def sort(cards) do
    Enum.sort_by(cards, &{&1.run_order, suit_rank(&1)})
  end

  def get_value_by_card_code(card_code) do
    types()
    |> Enum.find(&(String.first(card_code) == String.first(&1)))
    |> value()
  end

  defp value("Ace"), do: 1
  defp value(type) when type in ~w[Jack Queen King], do: 10
  defp value(type), do: String.to_integer(type)

  defp run_order("Ace"), do: 1
  defp run_order("Jack"), do: 11
  defp run_order("Queen"), do: 12
  defp run_order("King"), do: 13
  defp run_order(type), do: String.to_integer(type)

  defp set_code(type, suit) do
    String.first(type) <> String.first(suit)
  end

  defp suit_rank(%__MODULE__{suit: suit}) do
    Enum.find_index(suits(), &(&1 == suit))
  end
end
