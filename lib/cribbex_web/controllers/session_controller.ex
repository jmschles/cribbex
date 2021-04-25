defmodule CribbexWeb.SessionController do
  use CribbexWeb, :controller

  def set(conn, %{"name" => name}), do: store_string(conn, :name, name)
  def set(conn, %{"gameId" => game_id}), do: store_string(conn, :game_id, game_id)

  defp store_string(conn, key, value) do
    conn
    |> put_session(key, value)
    |> json("OK!")
  end
end
