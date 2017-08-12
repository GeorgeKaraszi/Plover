# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :plover,
  ecto_repos: [Plover.Repo]

# Configures the endpoint
config :plover, PloverWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Vm/TgX11EjE9m/yL2M1wyguBQGwdwPPhFN2Al+clo1RWs6+xJ2OW1cytyav2zRKb",
  render_errors: [view: PloverWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Plover.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

config :ueberauth, Ueberauth,
  providers: [
    github:   {Ueberauth.Strategy.Github, [default_scope: "user,repo,notifications"]}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")


config :plover, Integration.Slack.Webhook, default_url: System.get_env("SLACK_WEB_HOOK_URL")
config :slack, api_token: System.get_env("SLACK_API_TOKEN")
