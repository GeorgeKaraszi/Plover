defmodule Plover.Github.Review do
  @moduledoc """
    An intemediate table that links users and pull request that need reviewing
  """
  use Plover, :model
  use Plover.Commands.CrudCommands,
      record_type: Plover.Github.Review,
      associations: [:user, :pull_request]

  alias Plover.Github.{Review, PullRequest}
  alias Plover.Account.User

  schema "github_reviews" do
    belongs_to :user, User
    belongs_to :pull_request, PullRequest
    timestamps()
  end

  def changeset_payload(%User{} = user, %PullRequest{} = pull_request) do
   %Review{
      user: user,
      pull_request: pull_request
    } |> changeset()
  end

  @doc false
  def changeset(%Review{} = reviewer, attrs \\ %{}) do
    reviewer
    |> cast(attrs, [:user_id, :pull_request_id])
    |> cast_assoc(:user)
    |> cast_assoc(:pull_request)
    |> validate_required([:user, :pull_request])
  end
end
