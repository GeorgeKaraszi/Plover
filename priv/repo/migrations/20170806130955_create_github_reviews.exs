defmodule Plover.Repo.Migrations.CreateGithubReviews do
  use Ecto.Migration

  def change do
    create table(:github_reviews) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :pull_request_id, references(:github_pull_requests, on_delete: :delete_all), null: false
      timestamps()
    end
  end
end
