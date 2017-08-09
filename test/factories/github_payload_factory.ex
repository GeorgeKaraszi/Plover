defmodule Plover.GithubPayloadFactory do
    @moduledoc false
    alias Faker.{Company, Internet}
    defmacro __using__(_opts) do
        quote do
            def github_payload_factory do
                %Integration.Github.Payload{
                    organization_name: Company.bs,
                    organization_url: Internet.url,
                    project_name: Company.bs,
                    project_url: Internet.url,
                    pull_name: Company.bullshit,
                    pull_url: Internet.url,
                    pull_status: Enum.random(["open", "closed"]),
                    reviewers: [Internet.slug]
                }
            end
        end
    end
end
