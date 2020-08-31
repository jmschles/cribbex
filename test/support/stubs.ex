defmodule Stubs do
  alias Cribbex.Models.{
    Game,
    Player
  }

  # remove me
  def test_game do
    dealer = %Player{name: "dealer"}
    non_dealer = %Player{name: "non_dealer"}

    %Game{
      player_names: [dealer.name, non_dealer.name],
      dealer: dealer,
      non_dealer: non_dealer
    }
  end
end
