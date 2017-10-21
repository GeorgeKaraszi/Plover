defmodule SlackMessenger do
  @moduledoc false
  use GenServer

  alias Plover.Slack
  alias Github.State

  @spec post_message(String.t) :: GenServer.on_start()
  def start_link(channel_name) do
    GenServer.start_link(__MODULE__, channel_name, name: __MODULE__)
  end

  def init(channel_name) do
    {:ok, channel_name}
  end

  @spec post_message(%State{}) :: :ok
  def post_message(github_state) do
    GenServer.cast(__MODULE__, {:send_message, github_state})
  end

  @spec destroy_messages(%State{}) :: :ok
  def destroy_messages(github_state) do
    GenServer.cast(__MODULE__, {:destroy_messages, github_state})
  end

  # Server Callbacks

  def handle_cast({:send_message, github_state}, channel_name) do
    Slack.post_to_slack!(channel_name, github_state)
    {:noreply, channel_name}
  end

  def handle_cast({:destroy_messages, github_state}, channel_name) do
    Slack.destroy_messages!(channel_name, github_state)
    {:noreply, channel_name}
  end
end
