defmodule Cribbex.Models.Message do
  defstruct [:text, :sender]

  def build(text, sender) do
    %__MODULE__{text: text, sender: sender}
    |> validate()
  end

  @max_message_length 64
  defp validate(%{text: text} = message) do
    case String.length(text) do
      0 ->
        {:error, "Messages cannot be blank"}

      n when n > @max_message_length ->
        {:error, "Messages cannot exceed #{@max_message_length} characters"}

      _valid ->
        message
    end
  end
end
