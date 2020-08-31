defmodule Cribbex.Presence do
  use Phoenix.Presence, otp_app: :cribbex, pubsub_server: Cribbex.PubSub
end
