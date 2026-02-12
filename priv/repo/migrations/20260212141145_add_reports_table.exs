defmodule RecruitmentTest.Repo.Migrations.AddReportsTable do
  use Ecto.Migration

  def change do
    create table("reports") do
      add :collaborator_id, references(:collaborators, type: :binary_id, on_delete: :nothing),
        null: false

      add :task_id, references(:tasks, type: :binary_id, on_delete: :nothing), null: false
      add :task_name, :string, null: false
      add :task_description, :text
      add :collaborator_name, :string, null: false
      add :completed_at, :utc_datetime, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:reports, [:task_id])
    create index(:reports, [:collaborator_id, :completed_at])
    create index(:reports, [:completed_at])
  end
end
