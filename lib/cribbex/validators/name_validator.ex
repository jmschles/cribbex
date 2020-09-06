defmodule Cribbex.NameValidator do
  def validate(name) do
    %{}
    |> check_length(name)
    |> check_chars(name)
    |> check_uniqueness(name)
    |> summarize()
  end

  defp check_chars(%{error: _} = result, _name), do: result

  defp check_chars(result, name) do
    if all_chars_valid?(name) do
      result
    else
      Map.put(result, :error, "Names may only contain letters, numbers, underscores, and dashes")
    end
  end

  defp check_length(%{error: _} = result, _name), do: result

  defp check_length(result, name) do
    case String.length(name) do
      n when n < 3 or n > 16 ->
        Map.put(result, :error, "Names must be between 3 and 16 characters")
      _n ->
        result
    end
  end

  defp check_uniqueness(%{error: _} = result, _name), do: result

  defp check_uniqueness(result, name) do
    if name_taken?(name) do
      Map.put(result, :error, "Sorry, that name is currently in use.")
    else
      result
    end
  end

  defp summarize(%{error: error}), do: {:error, error}
  defp summarize(_result), do: :ok

  # helpers

  @valid_chars "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
               |> String.codepoints()
  def all_chars_valid?(name) do
    name
    |> String.codepoints()
    |> Enum.all?(&Enum.member?(@valid_chars, &1))
  end

  def name_taken?(name) do
    CribbexWeb.LoginHandler.lobby_topic()
    |> Cribbex.Presence.list()
    |> Map.keys()
    |> Enum.member?(name)
  end
end
