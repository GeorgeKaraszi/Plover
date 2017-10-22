defmodule Plover.GithubStateFactory do
    @moduledoc false
    alias Faker.{Company, Internet}
    alias Github.State
    alias Plover.Account.User
    defmacro __using__(_opts) do
        quote do
            def github_state_factory do
                %State{
                    owners: [],
                    reviewers: [],
                    action_history: [],
                    targeted_users: [],
                    message_type: Company.name,
                    pull_request_url: Internet.url
                }
            end

            def assign_owner(%State{} = state) do
                %{state | owners: [reviewer_setup("owner") | state.owners]}
            end

            def assign_reviewer(%State{} = state, user_state \\ "pull_request") do
                %{state | reviewers: [reviewer_setup(state) | state.reviewers]}
            end

            def assign_reviewers(%State{} = state, count \\ 2, user_state \\ "pull_request") do
                reviewers = for _n <- 1..count, do: reviewer_setup(user_state)
                %{state | reviewers: reviewers ++ state.reviewers}
            end

            defp reviewer_setup(user_state) do
                %User{github_login: github, slack_login: slack} = insert(:user)
                {github, slack, user_state}
            end
        end
    end
end
