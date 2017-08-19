defmodule Plover.Slack do
    @moduledoc """
        Post's and updates to a specified slack channel.
        Messages are logged for every success slack reaponse we get back
    """

    alias Plover.Repo
    alias Plover.Slack.Message
    alias Slack.Web.{Chat, Channels, Users}
    alias Plover.Commands.ErrorCommands

    @doc """
        This will attempt to find an existing message in the database.
        - If is found, it will post an update to the existing slack message
          for the specified slack channel.

        - If no message is found, then it will post a new message to slack for the
          specified slack channel.

          Once a successful message has been posted, it will record the channels
          ID and Message Timestamp

          Returns
          - Map type, Slack message response
    """
    def post_review_request!(slack_ids, pull_url, channel_name: channel_name) do
        channel_name
        |> get_channel_id!
        |> post_review_request!(slack_ids, pull_url)
    end

    def post_review_request!(channel_id, slack_ids, pull_url) do
        case Message.find_by(pull_url: pull_url, channel_id: channel_id) do
            nil ->
                response  = post_slack_message(channel_id, pull_url, slack_ids)
                timestamp = Map.fetch!(response, "ts")
                new_message!(channel_id, pull_url, timestamp)
                response
            message ->
                update_slack_message(channel_id, message.timestamp, pull_url, slack_ids)
        end
    end

    @doc """
        Will submit a message to the speicifed slack channel
    """
    def post_slack_message(channel_id, pull_url, slack_ids) do
        [title, attachment] =
            slack_ids
            |> Enum.join(", ")
            |> format_slack_message(pull_url)

        Chat.post_message(
            channel_id,
            title,
            %{link_names: true, parse: :full, attachments: attachment}
        )
    end

    @doc """
        Will update an existing message on a speicifed slack channel
    """
    def update_slack_message(channel_id, timestamp, pull_url, slack_ids) do
        [title, attachments] =
            slack_ids
            |> Enum.join(", ")
            |> format_slack_message(pull_url)

        Chat.update(
            channel_id,
            title,
            timestamp,
            %{link_names: true, parse: :full, attachments: attachments}
        )
    end

    @doc """
        Creates a new message
    """
    def new_message!(channel_id, pull_url, timestamp) do
        params = %{channel_id: channel_id, pull_url: pull_url, timestamp: timestamp}
        changeset = %Message{} |> Message.changeset(params)
        case Repo.insert_or_update(changeset) do
            {:error, changeset} ->
                message = ErrorCommands.translate_errors(changeset.errors, join_by: " and ")
                raise(ArgumentError, message: message)
            {:ok, message} ->
                message
        end
    end

    @doc """
        Verifies if a use exists on the given slack chat
    """
    def user_exists?(_, []), do: false
    def user_exists?(slack_name, [%{"name" => name} | members]) do
        slack_name == name || user_exists?(slack_name, members)
    end
    def user_exists?(user_name) do
        user_name = String.trim(user_name)
        slack_name =
            if String.starts_with?(user_name, "@") do
                String.trim_leading(user_name, "@")
            else
                user_name
            end
        %{"members" => members} = Users.list
        user_exists?(slack_name, members)
    end

    defp get_channel_id!(_, []), do: raise(KeyError, message: "COULD NOT FIND CHANNEL ID!")
    defp get_channel_id!(channel_name, [channel | channels]) do
        %{"name" => name, "id" => id} = channel
        if name == channel_name do
            id
        else
            get_channel_id!(channel_name, channels)
        end
    end
    defp get_channel_id!(channel_name) do
        %{"channels" => channels} = Channels.list
        get_channel_id!(channel_name, channels)
    end

    defp format_slack_message(slack_ids, pull_url) do
        text = " HEY THERE'S A PULL REQUEST FOR #{slack_ids} !"
        attachment = [%{
            "title": pull_url,
            "title_link": pull_url,
            "text": "Try to review this as soon as you can!",
            "color": "#36a64f",
            "footer": "Plover Webhook Response"
        }] |> Poison.encode!()

        [text, [attachment]]
    end
end
