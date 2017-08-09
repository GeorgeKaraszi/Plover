defmodule Plover.Github.PullRequest do
  @moduledoc """
    Pull request schema that will hold data
    pretaining to pending pull requests on a Projects PR
  """
  use Plover, :model
  use Plover.Commands.CrudCommands,
      record_type: Plover.Github.PullRequest,
      associations: [:github_project, :users]

  alias Plover.Github.{PullRequest, Project}
  alias Integration.Github.Payload

  schema "github_pull_requests" do
    field :name, :string
    field :url, :string
    field :is_open, :boolean

    belongs_to :github_project, Project
    many_to_many :users, Plover.Account.User, join_through: "github_reviews"

    timestamps()
  end

  def changeset_payload(%Project{} = project, payload \\ %Payload{}) do
    %PullRequest{
      name: payload.pull_name,
      url: payload.pull_url,
      is_open: String.contains?(payload.pull_status, "open"),
      github_project: project
    } |> changeset()
  end

  @doc false
  def changeset(%PullRequest{} = pull_request, attrs \\ %{}) do
    pull_request
    |> cast(attrs, [:url, :is_open, :github_project_id])
    |> cast_assoc(:github_project)
    |> validate_required([:url, :is_open])
  end
end
