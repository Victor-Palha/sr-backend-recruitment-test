defmodule RecruitmentTestWeb.Graphql.Types.Report do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  @desc "Paginated reports result"
  object :paginated_reports do
    field(:data, non_null(list_of(non_null(:report))))
    field(:page_info, non_null(:page_info))
  end

  @desc "A report for a completed task"
  object :report do
    field(:id, non_null(:id), description: "The unique identifier of the report")
    field(:task_name, non_null(:string), description: "The name of the task at completion time")

    field(:task_description, :string,
      description: "The description of the task at completion time"
    )

    field(:collaborator_name, non_null(:string),
      description: "The name of the collaborator at completion time"
    )

    field(:completed_at, non_null(:datetime), description: "When the task was completed")

    @desc "The collaborator who completed the task, resolved using Dataloader for efficient batching"
    field :collaborator, non_null(:collaborator) do
      resolve(dataloader(RecruitmentTest.Contexts.Content, :collaborator, []))
    end

    @desc "The task that was completed, resolved using Dataloader for efficient batching"
    field :task, non_null(:task) do
      resolve(dataloader(RecruitmentTest.Contexts.Content, :task, []))
    end

    field(:inserted_at, non_null(:datetime), description: "When the report was created")
  end

  @desc "Report filters"
  input_object :report_filters do
    field(:collaborator_id, :id)
    field(:task_id, :id)
  end

  @desc "Input type for creating a new report"
  input_object :create_report_input do
    field(:collaborator_id, non_null(:id), description: "The ID of the collaborator")
    field(:task_id, non_null(:id), description: "The ID of the task")
    field(:task_name, non_null(:string), description: "The name of the task at completion time")

    field(:task_description, :string,
      description: "The description of the task at completion time"
    )

    field(:collaborator_name, non_null(:string),
      description: "The name of the collaborator at completion time"
    )

    field(:completed_at, non_null(:datetime), description: "When the task was completed")
  end
end
