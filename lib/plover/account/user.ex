defmodule Plover.Account.User do
    @moduledoc false

    use Plover, :model
    use Plover.Commands.CrudCommands,
        record_type:  User,
        associations: []

    schema "users" do
        field :first_name, :string
        field :last_name, :string
        field :email, :string
        field :token, :string

        timestamps()
    end

    @doc false
    def changeset(%User{} = user, attrs) do
        user
        |> cast(attrs, [:first_name, :last_name, :email, :token])
        |> validate_required([:first_name, :last_name, :email, :token])
    end
end
