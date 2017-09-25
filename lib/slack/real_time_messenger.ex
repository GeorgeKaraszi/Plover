defmodule Slack.RealTimeMessenger do
  @moduledoc false
  use GenServer

  alias Plover.Slack
  alias Github.State

  def start_link(channel_name) do
    GenServer.start_link(__MODULE__, channel_name, name: __MODULE__)
  end

  def init(channel_name) do
    {:ok, channel_name}
  end

  def post_message(github_state \\ %State{}) do
    GenServer.cast(__MODULE__, {:send_message, github_state})
  end

  # Server Callbacks

  def handle_cast({:send_message, github_state}, channel_name) do
    Slack.post_to_slack!(channel_name, github_state)
    {:noreply, channel_name}
  end
end
