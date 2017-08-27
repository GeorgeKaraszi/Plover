defmodule Plover.Github.Project do
  @moduledoc """
    Github Project schema that will hold data
    pretaining to the project hosted on Github
  """
  use Plover, :model

  alias Plover.Github.Project
  alias Integration.Github.Payload

  schema "github_projects" do
    field :name, :string
    field :url, :string
    field :organization_name, :string
    field :organization_url, :string

    has_many :pull_requests,
              Plover.Github.PullRequest,
              on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset_payload(payload \\ %Payload{}) do
    attrs = %{
      name: payload.project_name,
      url: payload.project_url,
      organization_name: payload.organization_name,
      organization_url: payload.organization_url
    }

    %Project{} |> changeset(attrs)
  end

  @doc false
  def changeset(%Project{} = project, attrs \\ %{}) do
    project
    |> cast(attrs, [:name, :url, :organization_name, :organization_url])
    |> validate_required([:name, :url])
  end
end
