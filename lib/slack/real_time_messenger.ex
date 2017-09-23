defmodule Slack.RealTimeMessenger do
  @moduledoc false
  use GenServer

  def start_link(channel_name) do
    GenServer.start_link(__MODULE__, channel_name, name: __MODULE__)
  end

  def init(channel_name) do
    {:ok, channel_name}
  end

  def post_message(github_state) do
    GenServer.cast(__MODULE__, {:send_message, github_state})
  end

  # Server Callbacks

  def handel_cast({:send_message, _github_state}, _from, channel_name) do
    {:no_reply, channel_name}
  end
end
