defmodule RecruitmentTestWeb.Graphql.Types.Task do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  @desc "Paginated tasks result"
  object :paginated_tasks do
    field(:data, non_null(list_of(non_null(:task))))
    field(:page_info, non_null(:page_info))
  end

  @desc "Task status enum"
  enum :task_status do
    value(:pending, as: "pending", description: "Task is pending")
    value(:in_progress, as: "in_progress", description: "Task is in progress")
    value(:completed, as: "completed", description: "Task is completed")
    value(:failed, as: "failed", description: "Task has failed")
  end

  @desc "A task assigned to a collaborator"
  object :task do
    field(:id, non_null(:id), description: "The unique identifier of the task")
    field(:name, non_null(:string), description: "The name of the task")
    field(:description, :string, description: "A detailed description of the task")
    field(:status, non_null(:task_status), description: "The current status of the task")
    field(:priority, non_null(:integer), description: "The priority level of the task")

    @desc "The collaborator assigned to this task, resolved using Dataloader for efficient batching"
    field :collaborator, non_null(:collaborator) do
      resolve(dataloader(RecruitmentTest.Contexts.Content, :collaborator, []))
    end

    @desc "The report associated with this task, if completed, resolved using Dataloader for efficient batching"
    field :report, :report do
      resolve(dataloader(RecruitmentTest.Contexts.Content, :report, []))
    end

    field(:inserted_at, non_null(:naive_datetime), description: "When the task was created")
    field(:updated_at, non_null(:naive_datetime), description: "When the task was last updated")
  end

  @desc "Task filters"
  input_object :task_filters do
    field(:status, :task_status)
    field(:collaborator_id, :id)
    field(:priority, :integer)
  end

  @desc "Input type for creating a new task"
  input_object :create_task_input do
    field(:name, non_null(:string), description: "The name of the task")
    field(:description, :string, description: "A detailed description of the task")
    field(:collaborator_id, non_null(:id), description: "The ID of the collaborator")
    field(:status, :task_status, description: "The status of the task")
    field(:priority, :integer, description: "The priority level of the task")
  end

  @desc "Input type for updating an existing task"
  input_object :update_task_input do
    field(:name, :string, description: "The name of the task")
    field(:description, :string, description: "A detailed description of the task")
    field(:status, :task_status, description: "The status of the task")
    field(:priority, :integer, description: "The priority level of the task")
  end
end
