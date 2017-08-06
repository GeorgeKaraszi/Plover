defmodule Plover.Repo.Migrations.CreateGithubPullRequests do
  use Ecto.Migration

  def change do
    create table(:github_pull_requests) do
      add :name, :string
      add :url, :string
      add :status, :integer
      add :github_project, references(:github_projects, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
