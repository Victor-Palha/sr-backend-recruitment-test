defmodule RecruitmentTest.Repo.Migrations.AddTasksTable do
  use Ecto.Migration

  def change do
    create table("tasks") do
      add(:name, :string, null: false)
      add(:description, :text)

      add(:collaborator_id, references(:collaborators, type: :binary_id, on_delete: :nothing), null: false)

      add(:status, :string, null: false, default: "pending")
      add(:priority, :integer, null: false, default: 0)

      timestamps()
    end

    create(index(:tasks, [:collaborator_id, :status]))
    create(index(:tasks, [:status, :priority]))
  end
end
