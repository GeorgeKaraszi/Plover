defmodule Plover.Github.PullRequest do
  @moduledoc """
    Pull request schema that will hold data
    pretaining to pending pull requests on a Projects PR
  """
  use Plover, :model

  alias Plover.Github.{PullRequest, Project}
  alias Integration.Github.Payload

  schema "github_pull_requests" do
    field :name, :string
    field :url, :string

    belongs_to :project, Project
    many_to_many :users, Plover.Account.User, join_through: "github_reviews"

    timestamps()
  end

  def changeset_payload(%Project{} = project, payload \\ %Payload{}) do
    %PullRequest{
      name: payload.pull_name,
      url: payload.pull_url,
      project: project
    } |> changeset()
  end

  @doc false
  def changeset(%PullRequest{} = pull_request, attrs \\ %{}) do
    pull_request
    |> cast(attrs, [:url, :project_id])
    |> cast_assoc(:project)
    |> validate_required([:url])
  end
end
