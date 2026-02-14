defmodule RecruitmentTest.Jobs.GenerateReport do
  @moduledoc """
  This job is responsible for generating a report for a given task.
  It takes the task's ID as an argument, retrieves the task and its associated collaborator from the database, and then creates a report entry in the reports table with the relevant information.
  """
  use Oban.Worker,
    queue: :reports,
    max_attempts: 3

  alias RecruitmentTest.Repo
  alias RecruitmentTest.Contexts.Reports.Report
  alias RecruitmentTest.Contexts.Tasks.Task
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => task_id}}) do
    case Repo.get(Task, task_id) do
      nil ->
        IO.puts("Task with ID #{task_id} not found.")
        :ok

      task ->
        case Repo.get(Collaborator, task.collaborator_id) do
          nil ->
            IO.puts("Collaborator with ID #{task.collaborator_id} not found.")
            :ok

          collaborator ->
            %Report{
              task_id: task.id,
              task_name: task.name,
              task_description: task.description,
              collaborator_id: collaborator.id,
              collaborator_name: collaborator.name,
              completed_at: DateTime.truncate(DateTime.utc_now(), :second)
            }
            |> Repo.insert()
        end
    end
  end
end
