defmodule Plover.Account do
    @moduledoc """
        A model for creating and managing the User account
    """
  use Plover, :context
  alias Plover.Account.User

  @spec all_by_github_login(list(String.t)) :: list(User.t)
  def all_by_github_login(github_logins) do
    Repo.all(from u in User, where: u.github_login in ^github_logins)
  end

  @spec all_by_github_login(String.t) :: User.t | nil
  def find_by_github(github_login) do
    User.find_by(github_login: github_login)
  end

  @doc """
      Returns a list of slack id's from a list of users
  """
  @spec pluck_slack_logins(list(String.t) | String.t) :: list(String.t) | String.t | nil
  def pluck_slack_logins(nil), do: nil
  def pluck_slack_logins(users) when is_list(users) do
      Enum.map(users, fn(user) -> user.slack_login end)
  end
  def pluck_slack_logins(user), do: user.slack_login

  @doc """
      Returns a changeset for the givn user
  """
  @spec changeset(struct) :: User.t
  def changeset(user) do
    User.changeset(user)
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
  def find_or_create_user(%{email: email} = user_params) do
    case User.find_by(email: email) do
        nil ->  new_user(user_params)
        user -> {:ok, user}
    end
  end

  @doc """
    Will attempt to update the User's Account

    Returns:
        {:ok, user} if success
        {:error, changeset} if failed
  """
  def update_user(user, params) do
    user.id
    |> User.find()
    |> User.update_changeset(params)
    |> Repo.update()
  end
end
