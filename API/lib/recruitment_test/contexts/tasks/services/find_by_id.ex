defmodule RecruitmentTest.Contexts.Tasks.Services.FindById do
  @moduledoc """
  Service module responsible for finding a task by its ID.
  """

  alias RecruitmentTest.Contexts.Tasks.Task
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo
  import Ecto.Query

  require Logger

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    Logger.debug("Finding task by ID", service: "tasks.find_by_id", task_id: id)

    from(t in Task, where: t.id == ^id)
    |> Repo.one()
    |> case do
      nil ->
        Logger.debug("Task not found", service: "tasks.find_by_id", task_id: id)
        {:error, "Task not found"}

      task ->
        {:ok, task}
    end
  end

  def call(_id) do
    Logger.debug("Task lookup with invalid ID", service: "tasks.find_by_id")
    {:error, "Task not found"}
  end
end
