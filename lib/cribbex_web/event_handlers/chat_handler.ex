defmodule CribbexWeb.ChatHandler do
  import Phoenix.LiveView.Utils, only: [clear_flash: 1, put_flash: 3, assign: 3]

  alias Cribbex.Models.Message

  def handle_event(
        "sent",
        %{"text" => text, "channel" => channel},
        %{assigns: %{messages: messages, name: name}} = socket
      ) do
    case Message.build(text, name) do
      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, reason)}

      %Message{} = message ->
        broadcast_message(message, channel)

        {:noreply,
         socket |> clear_flash() |> assign(:messages, add_and_truncate(message, messages))}
    end
  end

  def handle_info("received", message, %{assigns: %{messages: messages}} = socket) do
    {:noreply, assign(socket, :messages, add_and_truncate(message, messages))}
  end

  def broadcast_message(message, channel) do
    CribbexWeb.Endpoint.broadcast_from(self(), channel, "chat:received", message)
  end

  # this is really just a hack because I can't get scrolling to work
  @max_message_count 14
  def add_and_truncate(message, messages) do
    Enum.take([message | messages], @max_message_count)
  end
end
