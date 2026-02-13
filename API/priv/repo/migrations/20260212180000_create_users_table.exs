defmodule RecruitmentTest.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table("users") do
      add :name, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :is_active, :boolean, default: true, null: false
      add :role, :string, null: false
      add :deleted_at, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:is_active])
    create index(:users, [:role])
  end
end
