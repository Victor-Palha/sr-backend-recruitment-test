defmodule RecruitmentTest.Reports.Report do
  use RecruitmentTest.Schema

  import Ecto.Changeset

  schema "reports" do
    field :task_name, :string
    field :task_description, :string
    field :collaborator_name, :string
    field :completed_at, :utc_datetime

    belongs_to :collaborator, RecruitmentTest.Collaborators.Collaborator
    belongs_to :task, RecruitmentTest.Tasks.Task

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :collaborator_id,
      :task_id,
      :task_name,
      :task_description,
      :collaborator_name,
      :completed_at
    ])
    |> validate_required([
      :collaborator_id,
      :task_id,
      :task_name,
      :collaborator_name,
      :completed_at
    ])
    |> validate_length(:task_name, max: 250)
    |> validate_length(:task_description, max: 5000)
    |> validate_length(:collaborator_name, max: 250)
    |> unique_constraint(:task_id)
    |> foreign_key_constraint(:collaborator_id)
    |> foreign_key_constraint(:task_id)
  end
end
