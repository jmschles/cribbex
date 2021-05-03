defmodule CribbexWeb.SessionController do
  use CribbexWeb, :controller

  def login(conn, %{"name" => name}) do
    conn
    |> put_session(:name, name)
    |> json("OK!")
  end

  def logout(conn, _payload) do
    conn
    |> delete_session(:name)
    |> json("Bye!")
  end
end
