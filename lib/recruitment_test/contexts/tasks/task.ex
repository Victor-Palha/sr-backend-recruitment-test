defmodule RecruitmentTest.Contexts.Tasks.Task do
  use RecruitmentTest.Schema

  import Ecto.Changeset

  @valid_statuses ~w(pending in_progress completed failed)

  schema "tasks" do
    field :name, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :priority, :integer, default: 0

    belongs_to :collaborator, RecruitmentTest.Contexts.Collaborators.Collaborator
    has_one :report, RecruitmentTest.Contexts.Reports.Report

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :name,
      :description,
      :collaborator_id,
      :status,
      :priority
    ])
    |> validate_required([:name, :collaborator_id, :status, :priority])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_length(:name, max: 250)
    |> validate_length(:description, max: 5000)
    |> validate_number(:priority, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:collaborator_id)
  end
end
