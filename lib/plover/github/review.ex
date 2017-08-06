defmodule Plover.Github.Review do
  @moduledoc """
    An intemediate table that links users and pull request that need reviewing
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Plover.Github.Review


  schema "github_reviews" do
    belongs_to :user, Plover.Account.User
    belongs_to :github_pull_request, Plover.Github.PullRequest
    timestamps()
  end

  @doc false
  def changeset(%Review{} = reviewer, attrs \\ %{}) do
    reviewer
    |> cast(attrs, [:user_id, :github_pull_request_id])
    |> cast_assoc(:user)
    |> cast_assoc(:github_pull_request)
    |> validate_required([])
  end
end
