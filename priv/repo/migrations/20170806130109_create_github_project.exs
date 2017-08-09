defmodule Plover.Repo.Migrations.CreateGithubProject do
  use Ecto.Migration

  def change do
    create table(:github_projects) do
      add :name, :string
      add :url, :string
      add :organization_name, :string
      add :organization_url, :string

      timestamps()
    end

  end
end
