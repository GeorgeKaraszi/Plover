defmodule Plover.Review.SubmittedTest do
    @moduledoc false
  use Plover.DataCase, async: true

  alias Plover.Review.Submitted

  describe "review approved" do
      test "returns an error if not fully approved" do
        {:error, _message} =
          :github_payload
          |> build(review_state: "approved")
          |> with_owner
          |> with_reviewer
          |> with_reviewers(2)
          |> Submitted.review()
      end

      test "successfully returns if fully approved" do
        user = insert(:user)

        {_state, owner, _pull_url} =
          :github_payload
          |> build(review_state: "approved")
          |> with_owner(user)
          |> with_reviewer
          |> Submitted.review()

          assert owner == user.slack_login
      end
  end

  describe "review changes requested" do
    test "returns an error if not fully approved" do
      user = insert(:user)

      {_state, owner, _pull_url} =
        :github_payload
        |> build(review_state: "changes_requested")
        |> with_owner(user)
        |> with_reviewer
        |> Submitted.review()

        assert owner == user.slack_login
    end
  end

  describe "Unknown review state" do
    test "It should return an error if state is unknown" do
      payload = build(:github_payload, review_state: "unknown_action")
      {:error, _message} =
        :github_payload
        |> build(review_state: "unknown_action")
        |> Submitted.review()
    end
  end
end
