defmodule Plover.GitHubProjectFactory do
    @moduledoc false
    alias Faker.{Company, Internet}
    defmacro __using__(_opts) do
        quote do
            def github_project_factory do
                %Plover.Github.Project{
                    name: Company.bullshit,
                    url: Internet.url,
                    organization_name: Company.name,
                    organization_url: Internet.url
                }
            end
        end
    end
end
