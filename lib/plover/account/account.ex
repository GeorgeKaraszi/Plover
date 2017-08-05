defmodule Plover.Account do
    @moduledoc """
        A model for creating and managing the User account
    """
  alias Plover.Account.User
  alias Plover.Repo

  def new_user(params) do
    %User{} |> User.changeset(params) |> Repo.insert
  end

  def update_or_insert_user(%{email: email} = user_params) do
    case User.find_by(email: email) do
        nil ->
            new_user(user_params)
        user ->
            {:ok, user}
    end
  end
end
