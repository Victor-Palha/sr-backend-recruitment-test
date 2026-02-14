defmodule RecruitmentTest.Repo.Migrations.AddContractsTable do
  use Ecto.Migration

  def change do
    create table("contracts") do
      add(:enterprise_id, references(:enterprises, type: :binary_id, on_delete: :nothing), null: false)

      add(:collaborator_id, references(:collaborators, type: :binary_id, on_delete: :nothing), null: false)

      add(:value, :decimal, precision: 10, scale: 2)
      add(:starts_at, :utc_datetime, null: false)
      add(:expires_at, :utc_datetime, null: false)
      add(:status, :string, null: false, default: "active")

      timestamps()
    end

    create(index(:contracts, [:collaborator_id, :status]))
    create(index(:contracts, [:enterprise_id, :status]))
  end
end
