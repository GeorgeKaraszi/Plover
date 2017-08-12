defmodule Plover.GitHubReviewFactory do
    @moduledoc false

    alias Plover.Github.{Review, PullRequest}
    defmacro __using__(_opts) do
        quote do
            def github_review_factory do
                %Plover.Github.Review{
                    user: build(:user),
                    pull_request: build(:github_pull_request)
                }
            end

            def with_pull_request(%Review{} = review, %PullRequest{} = pull_request) do
                %{review | pull_request: pull_request}
            end
        end
    end
end
