defmodule Plover.GithubPayloadFactory do
    @moduledoc false
    alias Faker.{Company, Internet}
    alias Integration.Github.Payload
    alias Plover.Account.User
    defmacro __using__(_opts) do
        quote do
            def github_payload_factory do
                %Payload{
                    action: Enum.random(["submitted", "requested_review"]),
                    organization_name: Company.bs,
                    organization_url: Internet.url,
                    project_name: Company.bs,
                    project_url: Internet.url,
                    pull_name: Company.bullshit,
                    pull_url: Internet.url,
                    pull_status: Enum.random(["open", "closed"]),
                    pull_owner: nil,
                    review_state: Enum.random(["approved", "changes_requested"]),
                    reviewer: nil,
                    reviewers: [],
                    requested_reviewer: nil,
                    has_been_merged: false,
                    has_been_closed: false,
                }
            end

            def has_been_reviewed(%Payload{} = payload, review_state: review_state) do
                %{payload | action: "submitted", review_state: review_state}
            end

            def with_owner(%Payload{} = payload), do: with_owner(payload, insert(:user))
            def with_owner(%Payload{} = payload, %User{} = user) do
                %{payload | pull_owner: user.github_login}
            end

            def with_reviewer(%Payload{} = payload), do: with_reviewer(payload, insert(:user))
            def with_reviewer(%Payload{} = payload, %User{} = user) do
                %{payload | reviewer: user.github_login, requested_reviewer: user.github_login}
            end

            def with_reviewers(%Payload{} = payload, users) when is_list(users) do
                logins = Enum.map(users, fn(user) -> user.github_login end)
                %{payload | reviewers: logins}
            end

            def with_reviewers(%Payload{} = payload, count) do
                with_reviewers(payload, insert_list(count, :user))
            end
        end
    end
end
