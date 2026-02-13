defmodule RecruitmentTestWeb.Graphql.Types.Report do
  use Absinthe.Schema.Notation

  @desc "A report for a completed task"
  object :report do
    field :id, non_null(:id), description: "The unique identifier of the report"
    field :task_name, non_null(:string), description: "The name of the task at completion time"

    field :task_description, :string,
      description: "The description of the task at completion time"

    field :collaborator_name, non_null(:string),
      description: "The name of the collaborator at completion time"

    field :completed_at, non_null(:datetime), description: "When the task was completed"

    field :collaborator, non_null(:collaborator),
      description: "The collaborator who completed the task"

    field :task, non_null(:task), description: "The task that was completed"

    field :inserted_at, non_null(:datetime), description: "When the report was created"
  end

  @desc "Input type for creating a new report"
  input_object :create_report_input do
    field :collaborator_id, non_null(:id), description: "The ID of the collaborator"
    field :task_id, non_null(:id), description: "The ID of the task"
    field :task_name, non_null(:string), description: "The name of the task at completion time"

    field :task_description, :string,
      description: "The description of the task at completion time"

    field :collaborator_name, non_null(:string),
      description: "The name of the collaborator at completion time"

    field :completed_at, non_null(:datetime), description: "When the task was completed"
  end
end
