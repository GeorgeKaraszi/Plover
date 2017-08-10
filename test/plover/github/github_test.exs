defmodule Plover.Github.GithubTest do
    @moduledoc false
  use Plover.DataCase

  alias Plover.{Github, Github.Review}

  test ".assign_reviewers" do
    review_count = fn -> Review.count end
    action       = fn ->
        payload   = :github_payload |> build() |> with_reviewer()
        :github_pull_request
        |> insert()
        |> Github.assign_reviewers(payload)
    end

    changed(review_count, action, by: 1)
  end
end
