defmodule Plover.Repo.Migrations.AddGitAndSlackLoginNamesToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :github_login, :string
      add :slack_login, :string
    end
  end
end
