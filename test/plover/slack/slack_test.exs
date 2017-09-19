defmodule Plover.Slack.SlackTest do
    @moduledoc false

    # Turning ASYNC on with mocks could lead to issue's down the line!
  use Plover.DataCase, async: true

  alias Plover.Slack.Message
  import Mock

  setup_with_mocks([
    {
        Slack.Web.Chat,
        [],
        [
            post_message: fn(_, _ , %{attachments: [attachment]}) -> attachment end,
        ]
    },
    {
        Plover.Slack,
        [:passthrough],
        []
    }
  ]) do
    {:ok, foo: "bar"}
  end

  describe "find_message!" do

    test "returns nil if one doesn't exist" do
        assert Plover.Slack.find_message("123") == nil
    end

    test "it returns nil if the message that exists is older than 1 day" do
        insert(:slack_message, uuid: "123", inserted_at: ~N(2017-01-01 00:00:00))
        assert Plover.Slack.find_message("123") == nil
    end

    test "returns the message if one does exist within 1 day span" do
        insert(:slack_message, uuid: "123")
        assert Plover.Slack.find_message("123") != nil
    end

  end

  describe "post_slack_message!" do

    test "Pull request action returns *warning* color message" do
        [attachment] =
        "pull_request"
        |> Plover.Slack.post_slack_message!("1", "google.com", "@george")
        |> Poison.decode!()

        assert attachment["color"] == "warning"
    end

    test "Changes Requested action returns *danger* color message" do
        [attachment] =
        "changes_requested"
        |> Plover.Slack.post_slack_message!("1", "google.com", "@george")
        |> Poison.decode!()

        assert attachment["color"] == "danger"
    end

    test "Approved action returns *good* color message" do
        [attachment] =
        "approved"
        |> Plover.Slack.post_slack_message!("1", "google.com", "@george")
        |> Poison.decode!()

        assert attachment["color"] == "good"
    end

  end


  describe "new_message!" do
    test "It will build new unique messages" do
        subject = fn -> Message.count end
        action  = fn ->
            message = build(:slack_message)
            Plover.Slack.new_message!(
                message.timestamp,
                message.uuid,
                message.channel_id,
                message.pull_url
            )
        end

        expect_to_change(subject, action, by: 1)
    end


    test "It will fail if message changeset is invalid" do
        action = fn ->
            message = insert(:slack_message)
            Plover.Slack.new_message!(
                123,
                456,
                message.channel_id,
                message.pull_url
            )
        end

        expect_to_raise(ArgumentError, action)
    end
  end

end
