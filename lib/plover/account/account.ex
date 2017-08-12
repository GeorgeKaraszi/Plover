defmodule Plover.Account do
    @moduledoc """
        A model for creating and managing the User account
    """
  use Plover, :model
  alias Plover.Account.User

  def all_by_github_login(github_logins) do
    Repo.all(from u in User, where: u.github_login in ^github_logins)
  end

    @doc """
        Returns a list of slack id's from a list of users
    """
    def pluck_slack_logins(users) when is_list(users) do
        Enum.map(users, fn(user) -> user.slack_login end)
    end

  @doc """
    Creates a new user
  """
  def new_user(params) do
    %User{} |> User.changeset(params) |> Repo.insert
  end

  @doc """
    Will attempt to locate or create a new user

    Returns:
        {:ok, user} if success
        {:error, changeset} if failed
  """
  def update_or_insert_user(%{email: email} = user_params) do
    case User.find_by(email: email) do
        nil ->
            new_user(user_params)
        user ->
            {:ok, user}
    end
  end
end
