# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :cribbex, CribbexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "UUIIQk2DkWT9uG8NAjc8ApFcssvH0aH/76X09SjtbXdj3huu4d69Q6XwsD1ubMPm",
  render_errors: [view: CribbexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Cribbex.PubSub,
  live_view: [signing_salt: "uwf2Ks81"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
