defmodule Plover.Github.PullRequest do
  @moduledoc """
    Pull request schema that will hold data
    pretaining to pending pull requests on a Projects PR
  """
  use Plover, :model
  use Plover.Commands.CrudCommands,
      record_type: Plover.Github.PullRequest,
      associations: [:github_project, :users]
  alias Plover.Github.PullRequest


  schema "github_pull_requests" do
    field :status, :integer
    field :name, :string
    field :url, :string

    belongs_to :github_project, Plover.Github.Project
    many_to_many :users, Plover.Account.User, join_through: "github_reviews"

    timestamps()
  end

  @doc false
  def changeset(%PullRequest{} = pull_request, attrs \\ %{}) do
    pull_request
    |> cast(attrs, [:url, :status, :github_project_id])
    |> cast_assoc(:github_project)
    |> validate_required([:url, :status])
  end
end
