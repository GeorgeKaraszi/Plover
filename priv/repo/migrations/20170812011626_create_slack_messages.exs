defmodule Plover.Repo.Migrations.CreateSlackMessages do
  use Ecto.Migration

  def change do
    create table(:slack_messages) do
      add :timestamp, :string
      add :pull_url, :string
      add :channel_id, :string
      timestamps()
    end

    create unique_index(:slack_messages, [:pull_url, :channel_id])
  end
end
