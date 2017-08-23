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

    def update_to_create(uuid, slack_id, pull_url, channel_id) do

    end



    def post_to_slack(slack_ids, pull_url, message_type, channel_name: channel_name) do
        channel_id       = get_channel_id!(channel_name)
        slack_id_convert = id_to_string(slack_ids)
        uuid             = pull_url <> message_type
        case message_type do
            "pull_request" ->
                uuid = uuid |> to_uuid()
            "approved" ->
                uuid = uuid |> to_uuid()
            "changes_requested" ->
                uuid = uuid <> slack_id_convert |> to_uuid()

            type -> {:error, "unknown message type (#{type})"}
        end
    end

    def post!(slack_ids, pull_url, channel_name: channel_name) do
        channel_name
        |> get_channel_id!
        # |> post_approved!(pull_url)
    end


    defp id_to_string(arg) when is_list(arg), do: Enum.join(arg, ", ")
    defp id_to_string(arg), do: arg

    defp to_uuid(arg), do: UUID.uuid3(:nil, arg)

    def find_message(uuid, ending_time \\ "-1", format \\ "day") do
        from(m in Message,
        where: m.inserted_at >= from_now(^ending_time, ^format),
        where: m.uuid == ^uuid)
        |> Repo.one()
    end

    @doc """
        Will submit a message to the speicifed slack channel
    """
    def post_slack_message(channel_id, pull_url, slack_ids) do
        [title, attachment] =
            slack_ids
            |> Enum.join(", ")
            # |> format_slack_message(pull_url)

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
            # |> format_slack_message(pull_url)

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

    defp pull_request_message(slack_ids, pull_url) do
        " HEY THERE'S A PULL REQUEST FOR #{slack_ids} !"
        |> slack_message("Try to review this as soon as you can!", pull_url)
    end

    defp request_change_message(slack_id, pull_url) do
        " You've been requested to make some changes #{slack_id} "
        |> slack_message("You've been requested to make some changes", pull_url)
    end

    defp approved_message(slack_id, pull_url) do
        " You're PR as been fully approved! #{slack_id} "
        |> slack_message("Merge it in if all requirements have been met!", pull_url)

    end

    defp slack_message(text, sub_text, pull_url) do
        attchment = [%{
            "title": pull_url,
            "title_link": pull_url,
            "text": sub_text,
            "color": "#36a64f",
            "footer": "Plover Webhook Response"
        }] |> Poison.encode!()

        [text, [attachment]]
    end
end
