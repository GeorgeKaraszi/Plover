defmodule Plover.Repo.Migrations.AddMessageUUIDAndRemoveIsOpen do
  use Ecto.Migration

  def change do
    alter table(:github_pull_requests) do
      remove :is_open
    end

    alter table(:slack_messages) do
      add :uuid, :string
    end

    drop index(:slack_messages, [:pull_url, :channel_id])
  end
end
