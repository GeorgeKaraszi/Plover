defmodule Plover.Slack.Message do
  @moduledoc """
    Maintains a log of messages posted to a given channel
  """

  use Plover, :model
  use Plover.Commands.CrudCommands,
      record_type: Plover.Slack.Message,
      associations: []

  alias Plover.Slack.Message

  schema "slack_messages" do
    field :pull_url, :string
    field :timestamp, :string
    field :channel_id, :string

    timestamps()
  end

  @doc false
  def changeset(%Message{} = message, attrs \\ %{}) do
    message
    |> cast(attrs, [:timestamp, :pull_url, :channel_id])
    |> validate_required([:timestamp, :pull_url, :channel_id])
    |> unique_constraint(:pull_url, name: :slack_messages_pull_url_channel_id_index)
  end
end
