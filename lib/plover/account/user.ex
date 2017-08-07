defmodule Plover.Account.User do
    @moduledoc false

    use Plover, :model
    use Plover.Commands.CrudCommands,
        record_type:  Plover.Account.User,
        associations: []

    alias Plover.Account.User

    schema "users" do
        field :first_name, :string
        field :last_name, :string
        field :email, :string
        field :token, :string
        field :github_login, :string
        field :slack_login, :string

        many_to_many :github_pull_requests,
                     Plover.Github.PullRequest,
                     join_through: "github_reviews"

        has_many :github_pull_requests_projects,
                 through: [:github_pull_requests, :github_project]

        timestamps()
    end

    @doc false
    def changeset(%User{} = user, attrs) do
        attrs = Map.put(attrs, :github_login, "ploverreview")
        # user.slack_login = "ploverreview"

        user
        |> cast(attrs, [:first_name, :last_name, :email, :token, :github_login, :slack_login])
        |> validate_required([:first_name, :last_name, :email, :token])
    end
end
