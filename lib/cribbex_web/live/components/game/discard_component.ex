defmodule CribbexWeb.Game.DiscardComponent do
  use CribbexWeb, :live_component

  def player_data(%{dealer: dealer_data, non_dealer: non_dealer_data}, my_name) do
    Enum.find([dealer_data, non_dealer_data], &(&1.name == my_name))
  end

  def opponent_data(%{dealer: dealer_data, non_dealer: non_dealer_data}, my_name) do
    Enum.find([dealer_data, non_dealer_data], &(&1.name != my_name))
  end
end
