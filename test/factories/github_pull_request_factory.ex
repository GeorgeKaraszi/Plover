defmodule Plover.GitHubPullRequestFactory do
    @moduledoc false
    alias Faker.{Company, Internet}
    defmacro __using__(_opts) do
        quote do
            def github_pull_request_factory do
                %Plover.Github.PullRequest{
                    name: Company.bullshit,
                    url: Internet.url,
                    is_open: true,
                    project: build(:github_project),
                }
            end
        end
    end
end
