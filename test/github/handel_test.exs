defmodule Plover.Github.HandelTest do
    @moduledoc false
    use Plover.DataCase, async: true
    alias Github.{State, Handel}
    alias PayloadParser.Payload

    describe "adding reviewers" do

        test "should add existing reviewers to the worker's state" do
            payload = :github_payload |> build() |> with_reviewer()
            state =
                %State{}
                |> Handel.assign_reviewer(payload.requested_reviewer, "test_state")
                |> Handel.assign_reviewer("Not found", "test_state")

            assert Enum.count(state.reviewers) == 1
        end

        test "should not add reviewers that have not registered on the system" do
            payload = %Payload{requested_reviewer: "TestUser1"}
            state = Handel.assign_reviewer(%State{}, payload.requested_reviewer, "test_state")
            assert Enum.count(state.reviewers) == 0
        end
    end

    describe "Removing Reviewers" do

        test "Should remove matched reviewer in the existing state" do
            payload = build(:github_payload) |> with_reviewer()
            state =
                %State{reviewers: [{payload.requested_reviewer, "slack_dummy", "dummy_state"}]}
                |> Handel.remove_reviewer(payload.requested_reviewer)

            assert Enum.count(state.reviewers) == 0
        end

        test "Not providing a reviewer returns the current state" do
            state = %State{reviewers: [{"test_user", "slack_dummy", "dummy_state"}]}
            |> Handel.remove_reviewer(nil)

            assert Enum.count(state.reviewers) == 1
        end
    end

    describe "change user state" do
        test "It should change and replace the user's state" do
            reviewers = [{"test_user", "slack_dummy", "not_approved"},
                        {"test_user2", "slack_dummy2", "not_approved"}]

            state = %State{reviewers: reviewers}
                    |> Handel.change_user_state("test_user2", "approved")

            assert Enum.count(state.reviewers) == 2
            {_github, _slack, "approved"}     = List.keyfind(state.reviewers, "test_user2", 0)
            {_github, _slack, "not_approved"} = List.keyfind(state.reviewers, "test_user", 0)

        end
    end

    describe "processing message type" do

        test "It should return partial approval if not everyone has submitted a review" do
            state = %State{reviewers: [{nil, nil, "approved"}, {nil, nil, "not_approved"}]}
                    |> Handel.process_message_type("submitted", "approved")
            assert state.message_type == "partial_approval"
        end

        test "It should return fully approved if everyone has approved" do
            state =  %State{reviewers: [{nil, nil, "approved"}, {nil, nil, "approved"}]}
                    |> Handel.process_message_type("submitted", "approved")
            assert state.message_type == "fully_approved"
        end

        test "It returns different approval states based on approval level and who was removed" do

            # Has no reviewer's approved
            state = %State{reviewers: [{nil, nil, "not_approved"}]}
                    |> Handel.process_message_type("review_request_removed", nil)
            assert state.message_type == "pull_request"


            # Does not have all reviewers that are approved
            state = %State{reviewers: [{nil, nil, "approved"}, {nil, nil, "not_approved"}]}
                    |> Handel.process_message_type("review_request_removed", nil)
            assert state.message_type == "partial_approval"

            # Full of nothing but approved review's
            state = %State{reviewers: [{nil, nil, "approved"}, {nil, nil, "approved"}]}
                    |> Handel.process_message_type("review_request_removed", nil)
            assert state.message_type == "fully_approved"

        end

        test "It returns pull request when a review has been requested or removed" do
            state = Handel.process_message_type(%State{}, "review_requested", nil)
            assert state.message_type == "pull_request"

            state = Handel.process_message_type(%State{}, "review_request_removed", nil)
            assert state.message_type == "pull_request"
        end

        test "It returns changes_requested when PR has changes request submitted to it" do
            state = Handel.process_message_type(%State{}, "changes_requested", nil)
            assert state.message_type == "changes_requested"
        end
    end
end
