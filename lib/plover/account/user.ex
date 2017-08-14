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

    @insert_requirments ~w(first_name last_name email token github_login)a
    @update_requirements ~w(slack_login)a
    @cast_fields @insert_requirments ++ @update_requirements

    @doc false
    def changeset(%User{} = user, attrs \\ %{}) do
        user
        |> cast(attrs, @cast_fields)
        |> shared_changeset()
    end

    @doc false
    def update_changeset(%User{} = user, attrs \\ %{}) do
        user
        |> cast(attrs, @cast_fields)
        |> validate_required(@update_requirements)
        |> shared_changeset
    end

    @doc false
    def shared_changeset(changeset) do
        changeset
        |> validate_required(@insert_requirments)
    end
end
