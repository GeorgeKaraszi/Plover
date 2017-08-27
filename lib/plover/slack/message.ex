defmodule Plover.Slack.Message do
  @moduledoc """
    Maintains a log of messages posted to a given channel
  """

  use Plover, :model

  alias Plover.Slack.Message

  schema "slack_messages" do
    field :pull_url, :string
    field :timestamp, :string
    field :channel_id, :string
    field :uuid, :string

    timestamps()
  end

  @doc false
  def changeset(%Message{} = message, attrs \\ %{}) do
    message
    |> cast(attrs, [:timestamp, :pull_url, :channel_id, :uuid])
    |> validate_required([:timestamp, :pull_url, :channel_id, :uuid])
  end
end
