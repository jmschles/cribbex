defmodule Cribbex.Logic.Notifier do
  alias Cribbex.Models.Notification

  def add_notification(game_data, role, source, points \\ nil)

  def add_notification(
        %{dealer: %{notifications: notifications} = dealer} = game_data,
        :dealer,
        source,
        points
      ) do
    %{
      game_data
      | dealer: %{dealer | notifications: [Notification.build(source, points) | notifications]}
    }
  end

  def add_notification(
        %{non_dealer: %{notifications: notifications} = non_dealer} = game_data,
        :non_dealer,
        source,
        points
      ) do
    %{
      game_data
      | non_dealer: %{
          non_dealer
          | notifications: [Notification.build(source, points) | notifications]
        }
    }
  end
end
