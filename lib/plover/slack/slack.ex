defmodule Plover.Slack do
    @moduledoc """
        Post's and updates to a specified slack channel.
        Messages are logged for every success slack reaponse we get back
    """

    import Ecto.Query
    alias Plover.Repo
    alias Plover.Slack.{State, Message}
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
    @spec post_to_slack!(String.t, Github.State.t) :: {:ok, struct}
    def post_to_slack!(channel_name, github) do
        uuid  =  get_uuid(github.message_type, github.pull_request_url)
        slack = %State{
                message_type: github.message_type,
                pull_url: github.pull_request_url,
                channel_id: get_channel_id!(channel_name),
                targeted_users: id_to_string!(github.targeted_users)
            }
        case find_message(uuid) do
            nil ->
                slack
                |> post_slack_message!(github)
                |> Map.fetch!("ts")
                |> new_message!(uuid, slack)
            message ->
                post_slack_message!(slack, github, message.timestamp)
                {:ok, message}
        end
    end

    @doc """
        Removes any message that is related to a given pull request URL
    """
    @spec destroy_messages!(Github.State.t) :: {integer, nil}
    def destroy_messages!(%Github.State{pull_request_url: pull_url}) do
        Repo.delete_all(from m in Message, where: m.pull_url == ^pull_url)
    end

    @doc """
        Removes any message that are older than the specified ending time
        Defaults to removing messages that are 30 or more days old
    """
    @spec destroy_older_messages!(integer, String.t) :: {integer, nil}
    def destroy_older_messages!(ending_time \\ -30, format \\ "day") when ending_time < 0 do
        Repo.delete_all(
            from m in Message,
            where: m.inserted_at <= from_now(^ending_time, ^format)
        )
    end

    @doc """
        Returns the UUID of a message based on the combination of pull url, message type, and slack ids

        #Examples
        iex> Plover.Slack.get_uuid("Hello", "http://google.com")
        "6D9965489DBC280E47B4A226C5B39733"
    """
    @spec get_uuid(String.t, String.t) :: String.t
    def get_uuid(message_type, url), do: message_type <> url |> to_uuid()

    @doc """
        Will find a message based on the UUID and from what time frame it was created

        Default behavior will locate messages that are 24hr's or less since last created
    """
    def find_message(uuid, ending_time \\ -1, format \\ "day") do
        Repo.one(
            from m in Message,
            where: m.inserted_at >= from_now(^ending_time, ^format),
            where: m.uuid == ^uuid
        )
    end

    @doc """
        Will submit a message to the speicifed slack channel
    """
    def post_slack_message!(slack, github) do
        [title, attachment] = slack_message!(slack.message_type, slack, github)
        Chat.post_message(
            slack.channel_id,
            title,
            %{link_names: true, parse: :full, attachments: attachment}
        )
    end

    @doc """
        Will update an existing message on a speicifed slack channel
    """
    def post_slack_message!(slack, github, timestamp) do
        [title, attachment] = slack_message!(slack.message_type, slack, github)
        Chat.update(
            slack.channel_id,
            title,
            timestamp,
            %{link_names: true, parse: :full, attachments: attachment}
        )
    end

    @doc """
        Creates a new message
    """
    def new_message!(timestamp, uuid, %State{channel_id: channel_id, pull_url: url}) do
        params    = %{channel_id: channel_id, pull_url: url, timestamp: timestamp, uuid: uuid}
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
        %{"members" => members} = Users.list # Aliased Slack.Web.Users
        user_exists?(slack_name, members)
    end

    @doc """
        Converts a list of tuples into a single string of slack users

        #Example
        iex> [{0, "george", 2}, {0, "testuser", 2}]
        iex> |> Plover.Slack.id_to_string!()
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
        iex> channels = [%{"name" => "false_channel", "id" => 1}, %{"name" => "true_channel", "id" => 2}]
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
    def slack_message!("pull_request", slack, _github) do
        " HEY THERE'S A PULL REQUEST FOR #{slack.targeted_users} !"
        |> format_slack_message("Try to review this as soon as you can!", slack.pull_url, "warning")
    end

    def slack_message!("changes_requested", slack, _github) do
        " You've been requested to make some changes #{slack.targeted_users} "
        |> format_slack_message("You've been requested to make some changes", slack.pull_url, "danger")
    end

    def slack_message!("partial_approval", slack, github) do
        total_count    = Enum.count(github.reviewers)
        approval_count = Enum.reduce(github.reviewers, 0, fn(r, acc) ->
            if elem(r, 2) == "approved", do: acc + 1, else: acc
        end)

        percent = round((approval_count / total_count * 100))

        " You're PR as been #{approval_count}/#{total_count} (#{percent}%) approved! #{slack.targeted_users}"
        |> format_slack_message("Be patient and wait for all reviewers to complete their analysis.", slack.pull_url, "#4286f4")
    end

    def slack_message!("fully_approved", slack, _github) do
        " You're PR has been fully approved! #{slack.targeted_users} "
        |> format_slack_message("Merge it in if all requirements have been met!", slack.pull_url)
    end

    def slack_message!(type, slack, _github) do
        raise(ArgumentError, message: "Do not recognize (#{type}) message type from: #{slack.pull_url}")
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

    defp to_uuid(data, protocal \\ :md5) do
        protocal |> :crypto.hash(data) |> Base.encode16()
    end
end
