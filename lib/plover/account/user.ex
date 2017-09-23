defmodule Plover.Account.User do
    @moduledoc false

    use Plover, :model

    alias Plover.Account.User
    alias Plover.Slack

    schema "users" do
        field :first_name, :string
        field :last_name, :string
        field :email, :string
        field :token, :string
        field :github_login, :string
        field :slack_login, :string

        timestamps()
    end

    @insert_requirments ~w(first_name email token github_login)a
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
        |> validate_with_slack(:slack_login)
        |> shared_changeset()
    end

    @doc false
    def shared_changeset(changeset) do
        changeset |> validate_required(@insert_requirments)
    end

    @doc """
        Validates the slack name is inputted correctly and it exists on slack
    """
    def validate_with_slack(changeset, field, options \\ []) do
        validate_change(changeset, field, fn _, slack_login ->
          case String.starts_with?(slack_login, "@") do
            true -> validate_user_exists(slack_login, field, options)
            false -> [{field, options[:message] || "Required to start with an @ symbol"}]
          end
        end)
    end

    defp validate_user_exists(slack_login, field, options) do
        case Slack.user_exists?(slack_login) do
            true -> []
            false -> [{field, options[:message] || "Could not find your name on slack!"}]
        end
    end
end
