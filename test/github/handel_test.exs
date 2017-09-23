defmodule Plover.Github.HandelTest do
    @moduledoc false
    use Plover.DataCase, async: true
    alias Plover.Github.{State, Handel}
    alias Integration.Github.Payload

    describe "adding reviewers" do

        test "should add existing reviewers to the worker's state" do
            payload = :github_payload |> build() |> with_reviewers(3)
            state = Handel.assign_reviewers(%State{}, ["not found" | payload.reviewers], "test_state")
            assert Enum.count(state.reviewers) == 3
        end

        test "should not add reviewers that have not registered on the system" do
            payload = %Payload{reviewers: ["TestUser1", "TestUser2"]}
            state = Handel.assign_reviewers(%State{}, payload.reviewers, "test_state")
            assert Enum.count(state.reviewers) == 0
        end
    end

    describe "Removing Reviewers" do
        test "Should remove matched reviewer in the existing state" do
            payload = :github_payload |> build() |> with_reviewer()
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

end
