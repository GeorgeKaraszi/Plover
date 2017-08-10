defmodule Plover.GithubPayloadFactory do
    @moduledoc false
    alias Faker.{Company, Internet}
    alias Integration.Github.Payload
    alias Plover.Account.User
    defmacro __using__(_opts) do
        quote do
            def github_payload_factory do
                %Payload{
                    organization_name: Company.bs,
                    organization_url: Internet.url,
                    project_name: Company.bs,
                    project_url: Internet.url,
                    pull_name: Company.bullshit,
                    pull_url: Internet.url,
                    pull_status: Enum.random(["open", "closed"]),
                    reviewers: []
                }
            end

            def with_reviewer(%Payload{} = payload), do: with_reviewer(payload, insert(:user))
            def with_reviewer(%Payload{} = payload, %User{} = user) do
                %{payload | reviewers: [user.github_login]}
            end
        end
    end
end
