defmodule Plover.Application do
  @moduledoc false
  alias Mix.Config
  alias Plover.Repo
  alias PloverWeb.Endpoint

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    unless Mix.env == :prod do
      Envy.auto_load
      # Re-run config for the DOT env files to load envirmental variables
      "config/config.exs" |> Config.read! |> Config.persist

      unless Mix.env == :test, do: :observer.start
    end

    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Repo, []),
      # Start the endpoint when the application starts
      supervisor(Endpoint, []),
      supervisor(Github.Supervisor, []),
      # Start your own worker by calling: Plover.Worker.start_link(arg1, arg2, arg3)
      worker(Github, []),
      worker(SlackMessenger, [System.get_env("SLACK_CHANNEL_NAME")]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Plover.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
