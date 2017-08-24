defmodule Plover.Slack do
    @moduledoc """
        Post's and updates to a specified slack channel.
        Messages are logged for every success slack reaponse we get back
    """

    import Ecto.Query
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
          - The message changeset
    """
    def post_to_slack!(slack_ids, pull_url, message_type, channel_name) do
        channel_id       = get_channel_id!(channel_name)
        slack_id_convert = id_to_string(slack_ids)
        uuid             = get_uuid(pull_url, message_type, slack_id_convert)
        case find_message(uuid) do
            nil ->
                message_type
                |> post_slack_message!(channel_id, pull_url, slack_id_convert)
                |> Map.fetch!("ts")
                |> new_message!(uuid, channel_id, pull_url)
            message ->
                message_type
                |> update_slack_message!(message.timestamp, channel_id, pull_url, slack_id_convert)
                message
        end
    end

    @doc """
        Returns the UUID of a message based on the combination of pull url, message type, and slack ids
    """
    def get_uuid(pull_url, message_type, slack_id \\ "") do
        pull_url <> message_type <> slack_id |> to_uuid()
    end

    @doc """
        Will find a message based on the UUID and from what time frame it was created

        Default behavior will locate messages that are 24hr's or less since last created
    """
    def find_message(uuid, ending_time \\ "-1", format \\ "day") do
        Repo.one(
            from m in Message,
            where: m.inserted_at >= from_now(^ending_time, ^format),
            where: m.uuid == ^uuid
        )
    end

    @doc """
        Will submit a message to the speicifed slack channel
    """
    def post_slack_message!(message_type, channel_id, pull_url, slack_id) do
        [title, attachment] = slack_message!(message_type, slack_id, pull_url)
        Chat.post_message(
            channel_id,
            title,
            %{link_names: true, parse: :full, attachments: attachment}
        )
    end

    @doc """
        Will update an existing message on a speicifed slack channel
    """
    def update_slack_message!(message_type, timestamp, channel_id, pull_url, slack_id) do
        [title, attachment] = slack_message!(message_type, slack_id, pull_url)
        Chat.update(
            channel_id,
            title,
            timestamp,
            %{link_names: true, parse: :full, attachments: attachment}
        )
    end

    @doc """
        Creates a new message

        iex> Plover.Slack.new_message!(~N[2017-01-08 12:12:12], "good", "abc123", "google.com")
    """
    def new_message!(timestamp, uuid, channel_id, pull_url) do
        params    = %{channel_id: channel_id, pull_url: pull_url, timestamp: timestamp, uuid: uuid}
        changeset = Message.changeset(%Message{}, params)

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

    defp id_to_string(arg) when is_list(arg), do: Enum.join(arg, ", ")
    defp id_to_string(arg),                 do: arg
    defp to_uuid(arg),                      do: UUID.uuid3(:nil, arg)
    defp get_channel_id!(_, []),            do: raise(KeyError, message: "COULD NOT FIND CHANNEL ID!")
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

    defp slack_message!("pull_request", slack_id, pull_url) do
        " HEY THERE'S A PULL REQUEST FOR #{slack_id} !"
        |> format_slack_message("Try to review this as soon as you can!", pull_url, "warning")
    end

    defp slack_message!("changes_requested", slack_id, pull_url) do
        " You've been requested to make some changes #{slack_id} "
        |> format_slack_message("You've been requested to make some changes", pull_url, "danger")
    end

    defp slack_message!("approved", slack_id, pull_url) do
        " You're PR as been fully approved! #{slack_id} "
        |> format_slack_message("Merge it in if all requirements have been met!", pull_url)
    end

    defp slack_message!(type, _, _) do
        raise(ArgumentError, message: "Do not recognize (#{type}) message type")
    end

    defp format_slack_message(text, sub_text, pull_url, color \\ "good") do
        attachment = [%{
            "title": pull_url,
            "title_link": pull_url,
            "text": sub_text,
            "color": color,
            "footer": "Plover Webhook Response"
        }] |> Poison.encode!()

        [text, [attachment]]
    end
end
