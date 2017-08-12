defmodule Plover.SlackMessageFactory do
    @moduledoc false
    alias Faker.{Company, Internet}
    defmacro __using__(_opts) do
        quote do
            def slack_message_factory do
                %Plover.Slack.Message{
                    pull_url: Internet.url,
                    timestamp: Internet.slug,
                    channel_id: Company.name
                }
            end
        end
    end
end
