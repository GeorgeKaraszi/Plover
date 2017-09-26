defmodule Plover.Slack do
    @moduledoc """
        Post's and updates to a specified slack channel.
        Messages are logged for every success slack reaponse we get back
    """

    import Ecto.Query
    alias Plover.Repo
    alias Plover.Slack.Message
    alias Github.State
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
    def post_to_slack!(channel_name, github_state \\ %State{}) do
        message_type     = github_state.message_type
        pull_url         = github_state.pull_request_url
        channel_id       = get_channel_id!(channel_name)
        slack_ids        = id_to_string!(github_state.targeted_users)
        uuid             = get_uuid(pull_url, message_type, slack_ids)

        case find_message(uuid) do
            nil ->
                message_type
                |> post_slack_message!(channel_id, pull_url, slack_ids)
                |> Map.fetch!("ts")
                |> new_message!(uuid, channel_id, pull_url)
            message ->
                update_slack_message!(message_type, message.timestamp, channel_id, pull_url,
                    slack_ids)
                {:ok, message}
        end
    end

    @doc """
        Returns the UUID of a message based on the combination of pull url, message type, and slack ids
    """
    def get_uuid(pull_url, message_type, slack_id \\ "") do
        case message_type do
            action when action in ["approved", "changes_requested"] ->
                pull_url <> message_type <> slack_id |> to_uuid()
            _ ->
                pull_url <> message_type |> to_uuid()
        end
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
    """
    def new_message!(timestamp, uuid, channel_id, pull_url) do
        params    = %{channel_id: channel_id, pull_url: pull_url, timestamp: timestamp, uuid: uuid}
        changeset = Message.changeset(%Message{}, params)

        case Repo.insert_or_update(changeset) do
            {:error, changeset} ->
                message = ErrorCommands.translate_errors(changeset.errors, join_by: " and ")
                raise(ArgumentError, message: message)
            message -> message
        end
    end

    @doc """
        Verifies if a use exists on the given slack chat

        #Example
        iex> members = [%{"name" => "john"}, %{"name" => "george"}]
        iex> Plover.Slack.user_exists?("george", members)
        true
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

    @doc """
        Converts a list of tuples into a single string of slack users

        #Example
        iex> [{0, "george", 2}, {0, "testuser", 2}]
        iex> |> id_to_string()
        "george, testuser"
    """
    def id_to_string!(arg) when is_list(arg) and length(arg) >= 1 do
        arg |> Enum.map(fn r -> elem(r, 1) end) |> Enum.join(", ")
    end

    def id_to_string!(_) do
        raise(ArgumentError, message: "Require a populated list of tuple reviewers")
    end

    @doc """
        Returns the channel id of a list of channels

        #Example
        iex> channels = [%{"id": 1, "name": "false_channel"}, %{"id": 2, "name": "true_channel"}]
        iex> Plover.Slack.get_channel_id!("true_channel", channels)
        2
    """
    def get_channel_id!(_, []), do: raise(KeyError, message: "COULD NOT FIND CHANNEL ID!")

    def get_channel_id!(channel_name, [channel | channels]) do
        %{"name" => name, "id" => id} = channel
        if name == channel_name do
            id
        else
            get_channel_id!(channel_name, channels)
        end
    end

    def get_channel_id!(channel_name) do
        %{"channels" => channels} = Channels.list
        get_channel_id!(channel_name, channels)
    end

    @doc """
        Formats the slack message based on the provided message type action
    """
    def slack_message!("pull_request", slack_id, pull_url) do
        " HEY THERE'S A PULL REQUEST FOR #{slack_id} !"
        |> format_slack_message("Try to review this as soon as you can!", pull_url, "warning")
    end

    def slack_message!("changes_requested", slack_id, pull_url) do
        " You've been requested to make some changes #{slack_id} "
        |> format_slack_message("You've been requested to make some changes", pull_url, "danger")
    end

    def slack_message!("fully_approved", slack_id, pull_url) do
        " You're PR as been fully approved! #{slack_id} "
        |> format_slack_message("Merge it in if all requirements have been met!", pull_url)
    end

    def slack_message!(type, _, pull_url) do
        raise(ArgumentError, message: "Do not recognize (#{type}) message type from: #{pull_url}")
    end

    defp format_slack_message(title, sub_text, pull_url, color \\ "good") do
        attachment = [%{
            "title": pull_url,
            "title_link": pull_url,
            "text": sub_text,
            "color": color,
            "footer": "Plover Webhook Response"
        }] |> Poison.encode!()

        [title, [attachment]]
    end

    defp to_uuid(arg), do: UUID.uuid3(:nil, arg)
end
