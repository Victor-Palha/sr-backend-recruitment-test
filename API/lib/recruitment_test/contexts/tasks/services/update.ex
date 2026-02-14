defmodule RecruitmentTest.Contexts.Tasks.Services.Update do
  @moduledoc """
  Service module responsible for updating an existing task's details.
  """
  alias RecruitmentTest.Contexts.Tasks.Task
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo

  @spec call(
          id :: String.t(),
          attrs :: %{
            name: String.t() | nil,
            description: String.t() | nil,
            status: String.t() | nil,
            priority: number() | nil
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def call(id, attrs) when is_uuid(id) do
    with {:ok, task} <- does_task_exist(id),
         {:ok, updated_task} <- update_task(task, attrs) do
      generate_report_if_completed(updated_task)
      {:ok, updated_task}
    end
  end

  def call(_id, _attrs), do: {:error, "Task not found"}

  defp does_task_exist(id) do
    case RecruitmentTest.Contexts.Tasks.Services.FindById.call(id) do
      {:ok, task} -> {:ok, task}
      {:error, _reason} -> {:error, "Task not found"}
    end
  end

  defp update_task(task, attrs) do
    task
    |> Task.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, updated}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def generate_report_if_completed(task) do
    if was_task_completed?(task) do
      task
      |> Map.take([:id])
      |> Oban.Job.new(queue: :reports, worker: RecruitmentTest.Jobs.GenerateReport)
      |> Oban.insert()
    end
  end

  defp was_task_completed?(%Task{status: "completed"}), do: true
  defp was_task_completed?(_), do: false
end
