defmodule Plover.Slack.SlackTest do
    @moduledoc false
  use Plover.DataCase, async: true

  alias Plover.Slack
  alias Plover.Slack.Message

  describe ".new_message!" do
    test "It will build new unique messages" do
        subject = fn -> Message.count end
        action  = fn ->
            message = build(:slack_message)
            Slack.new_message!(message.channel_id, message.pull_url, message.timestamp)
        end

        expect_to_change(subject, action, by: 1)
    end

    test "It will fail if message is not uniuqe" do
        action = fn ->
            message = insert(:slack_message)
            Slack.new_message!(message.channel_id, message.pull_url, message.timestamp)
        end

        expect_to_raise(ArgumentError, action)
    end
  end

end
