defmodule Plover.Slack.SlackTest do
    @moduledoc false
  use Plover.DataCase, async: true

  alias Plover.Slack
  alias Plover.Slack.Message

  @moduletag :wip

  describe ".post_slack_message!" do
    test "Pull request action returns *warning* color message" do

    end

  end


  describe "new_message!" do
    test "It will build new unique messages" do
        subject = fn -> Message.count end
        action  = fn ->
            message = build(:slack_message)
            Slack.new_message!(
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
            Slack.new_message!(
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
