defmodule Plover.Github.Review do
  @moduledoc """
    An intemediate table that links users and pull request that need reviewing
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Plover.Github.{Review, PullRequest}
  alias Plover.Account.User

  schema "github_reviews" do
    belongs_to :user, User
    belongs_to :github_pull_request, PullRequest
    timestamps()
  end

  def changeset_payload(%User{} = user, %PullRequest{} = pull_request) do
   %Review{
      user: user,
      github_pull_request: pull_request
    } |> changeset()
  end

  @doc false
  def changeset(%Review{} = reviewer, attrs \\ %{}) do
    reviewer
    |> cast(attrs, [:user_id, :github_pull_request_id])
    |> cast_assoc(:user)
    |> cast_assoc(:github_pull_request)
    |> validate_required([:user, :github_pull_request])
  end
end
