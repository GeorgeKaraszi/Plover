defmodule Plover.Slack.SlackTest do
    @moduledoc false

    # Turning ASYNC on with mocks could lead to issue's down the line!
  use Plover.DataCase, async: true

  doctest Plover.Slack
  alias Plover.Slack.Message
  alias Github.State
  use Timex
  import Mock


  setup_with_mocks([
    {
        Slack.Web.Chat,
        [],
        [
            post_message: fn(_, _ , _) -> %{"ts" => "12345678"} end
        ]
    },
    {
        Slack.Web.Channels,
        [],
        [
            list: fn -> %{"channels" => [%{"name" => "TestChannel", "id" => "ABC"}]} end
        ]
    },
    {
        Plover.Slack,
        [:passthrough],
        []
    },
  ]) do

    {:ok, foo: "bar"}
  end

  describe "post_to_slack!" do

    test "New message should post to slack" do
        github = %State{
            message_type: "pull_request",
            pull_request_url: "http://google.com",
            reviewers: [{"TestUser1", "@TestUser1", "approved"}],
            targeted_users: [{"TestUser1", "@TestUser1", "approved"}]
        }

        {:ok, message} = Plover.Slack.post_to_slack!("TestChannel", github)
        assert message.timestamp == "12345678"
    end

  end

  describe "slack_message!" do
    test "pull_request" do
        slack_state = build(:slack_state) |> with_targets(2)
        [title, attachment] = Plover.Slack.slack_message!("pull_request", slack_state, nil)
        [decoded] = Poison.decode!(attachment)

        assert String.contains?(title, slack_state.targeted_users)
        assert decoded["color"] == "warning"
    end

    test "fully_approved" do
        slack_state = build(:slack_state) |> with_targets(1)
        [title, attachment] = Plover.Slack.slack_message!("fully_approved", slack_state, nil)
        [decoded] = Poison.decode!(attachment)

        assert String.contains?(title, slack_state.targeted_users)
        assert decoded["color"] == "good"
    end

    test "partial_approval" do
        slack_state = build(:slack_state) |> with_targets(1)
        github_state = %State{
            reviewers: [
                {"TestUser1", "@TestUser1", "approved"},
                {"TestUser2", "@TestUser2", "review_requested"}
            ]
        }

        [title, _] = Plover.Slack.slack_message!("partial_approval", slack_state, github_state)

        assert String.contains?(title, slack_state.targeted_users)
        assert String.contains?(title, "You're PR as been 1/2 (50%) approved!")
    end
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

  describe "new_message!" do
    test "It will build new unique messages" do
        subject = fn -> Message.count end
        action  = fn ->
            message = build(:slack_message)
            slack   = build(:slack_state)
            Plover.Slack.new_message!(message.timestamp, message.uuid, slack)
        end

        expect_to_change(subject, action, by: 1)
    end

    test "It will fail if message changeset is invalid" do
        action = fn ->
            slack = build(:slack_state)
            Plover.Slack.new_message!(123, 456, slack)
        end

        expect_to_raise(ArgumentError, action)
    end
  end

    describe "destroy_older_messages!" do
        test "It should remove old messages from the system" do
            time = Timex.now |> Timex.shift(days: -40)
            insert(:slack_message)
            insert(:slack_message, inserted_at: time)

            subject = fn -> Message.count end
            action  = fn -> Plover.Slack.destroy_older_messages! end
            expect_to_change(subject, action, from: 2, to: 1)
        end
    end
end
