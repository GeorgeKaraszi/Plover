defmodule Plover.GitHubReviewFactory do
    @moduledoc false
    defmacro __using__(_opts) do
        quote do
            def github_review_factory do
                %Plover.Github.Review{
                    user: build(:user),
                    github_pull_request: build(:github_pull_request)
                }
            end
        end
    end
end
