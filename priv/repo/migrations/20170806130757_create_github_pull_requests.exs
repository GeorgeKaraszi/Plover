defmodule Plover.Repo.Migrations.CreateGithubPullRequests do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:github_pull_requests) do
      add :name, :string
      add :url, :string
      add :is_open, :boolean
      add :project_id, references(:github_projects, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
