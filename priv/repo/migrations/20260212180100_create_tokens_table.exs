defmodule RecruitmentTest.Repo.Migrations.CreateTokensTable do
  use Ecto.Migration

  def change do
    create table("tokens") do
      add :token, :text, null: false
      add :type, :string, null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :expires_at, :utc_datetime, null: false
      add :revoked_at, :utc_datetime

      timestamps(updated_at: false)
    end

    create unique_index(:tokens, [:token])
    create index(:tokens, [:user_id])
    create index(:tokens, [:type])
    create index(:tokens, [:expires_at])
  end
end
