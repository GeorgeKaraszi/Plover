defmodule Plover.UserFactory do
    @moduledoc false
    alias Faker.{Internet, Name}

    defmacro __using__(_opts) do
        quote do
            def user_factory do
                %Plover.Account.User{
                    first_name: Name.first_name,
                    last_name: Name.last_name,
                    email: Internet.email,
                    github_login: Internet.slug,
                    slack_login: Internet.slug,
                    token: "ABC123",
                }
            end
        end
    end
end
