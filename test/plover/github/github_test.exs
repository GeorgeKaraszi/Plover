defmodule Plover.Github.GithubTest do
    @moduledoc false
  use Plover.DataCase, async: true

  alias Plover.{Github}
  alias Github.{Review, PullRequest, Project}

  describe ".assign_reviewers" do
    test "Works with existing pull request" do
      subject  = fn -> Review.count end
      action   = fn ->
          payload = :github_payload |> build() |> with_reviewer()
          :github_pull_request
          |> insert()
          |> Github.assign_reviewers(payload)
      end

      expect_to_change(subject, action, by: 1)
    end

    test "Works with newly created pull request" do
      subject = fn -> Review.count end
      action  = fn ->
          payload = :github_payload |> build() |> with_reviewer()
          {:ok, insert(:github_pull_request)}
          |> Github.assign_reviewers(payload)
      end

      expect_to_change(subject, action, by: 1)
    end

    test "Assigning reviews removes old ones" do
      user           = insert(:user)
      pull_request   = insert(:github_pull_request)
      payload        = :github_payload |> build() |> with_reviewer(user)
      insert_list(5, :github_review, pull_request: pull_request)

      inital = Review.count
      Github.assign_reviewers(pull_request, payload)
      then = Review.count

      assert inital == 5
      assert then   == 1
      assert Review.find_by(user_id: user.id) != nil
    end

  end

  describe ".assign_pull_request" do
    test "Assigning a pull request creates a new project if one doesn't exist" do
      subject = fn -> Project.count end
      action = fn ->
        :github_payload
        |> build(project_url: "http://google.com")
        |> with_reviewer()
        |> Github.assign_pull_request(preload: false)
      end

      expect_to_change(subject, action, from: 0, to: 1)
      expect_not_to_change(subject, action)
    end

    test "Assigning a pull request creates a new PR if one doesn't exist" do
      subject = fn -> PullRequest.count end
      action = fn ->
        :github_payload
        |> build(project_url: "http://google.com", pull_url: "http://google.com/1")
        |> with_reviewer()
        |> Github.assign_pull_request(preload: false)
      end

      expect_to_change(subject, action, from: 0, to: 1)
      expect_not_to_change(subject, action)
    end
  end
end
