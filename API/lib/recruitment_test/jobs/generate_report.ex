defmodule RecruitmentTest.Jobs.GenerateReport do
  @moduledoc """
  This job is responsible for generating a report for a given task.
  It takes the task's ID as an argument, retrieves the task and its associated collaborator from the database, and then creates a report entry in the reports table with the relevant information.
  """
  use Oban.Worker,
    queue: :reports,
    max_attempts: 3

  require Logger

  alias RecruitmentTest.Repo
  alias RecruitmentTest.Contexts.Reports.Report
  alias RecruitmentTest.Contexts.Tasks.Task
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => task_id}} = job) do
    Logger.metadata(oban_job_id: job.id, oban_worker: "GenerateReport", oban_queue: "reports")
    Logger.info("Generating report for task", job: "generate_report", task_id: task_id)

    case Repo.get(Task, task_id) do
      nil ->
        Logger.warning("Task not found for report generation",
          job: "generate_report",
          task_id: task_id
        )

        :ok

      task ->
        case Repo.get(Collaborator, task.collaborator_id) do
          nil ->
            Logger.warning("Collaborator not found for report generation",
              job: "generate_report",
              task_id: task_id,
              collaborator_id: task.collaborator_id
            )

            :ok

          collaborator ->
            result =
              %Report{
                task_id: task.id,
                task_name: task.name,
                task_description: task.description,
                collaborator_id: collaborator.id,
                collaborator_name: collaborator.name,
                completed_at: DateTime.truncate(DateTime.utc_now(), :second)
              }
              |> Repo.insert()

            case result do
              {:ok, report} ->
                Logger.info("Report generated successfully",
                  job: "generate_report",
                  task_id: task_id,
                  report_id: report.id
                )

                {:ok, report}

              {:error, changeset} ->
                Logger.error("Failed to generate report",
                  job: "generate_report",
                  task_id: task_id,
                  errors: inspect(changeset.errors)
                )

                {:error, changeset}
            end
        end
    end
  end
end
