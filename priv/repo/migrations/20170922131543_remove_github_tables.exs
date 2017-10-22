defmodule Plover.Repo.Migrations.RemoveGithubTables do
  use Ecto.Migration

  def change do
    drop table(:github_reviews)
    drop table(:github_pull_requests)
    drop table(:github_projects)
  end
end
