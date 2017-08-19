defmodule Plover.Review.AssignTest do
    @moduledoc false
  use Plover.DataCase, async: true

  alias Plover.Review.Assigned
  alias Plover.Github.{PullRequest, Project}

  describe ".review" do
    test "Assigning a pull request creates a new project if one doesn't exist" do
      subject = fn -> Project.count end
      action = fn ->
        :github_payload
        |> build(project_url: "http://google.com")
        |> with_reviewer()
        |> Assigned.review(preload: false)
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
        |> Assigned.review(preload: false)
      end

      expect_to_change(subject, action, from: 0, to: 1)
      expect_not_to_change(subject, action)
    end
  end
end
