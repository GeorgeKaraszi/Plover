defmodule Plover.SlackStateFactory do
    @moduledoc false
    alias Faker.{Company, Internet}
    defmacro __using__(_opts) do
        quote do
            def slack_state_factory do
                %Plover.Slack.State{
                    message_type: "pull_request",
                    pull_url: Internet.url,
                    targeted_users: Internet.slug,
                }
            end

            def with_targets(%Plover.Slack.State{} = state, number) do
                targeted_users = for c <- 1..number, do: Internet.slug
                %{state | targeted_users: Enum.join(targeted_users, ", ")}
            end
        end
    end
end
