defmodule RecruitmentTest.Contexts.Tasks.Services.FindById do
  @moduledoc """
  Service module responsible for finding a task by its ID.
  """

  alias RecruitmentTest.Contexts.Tasks.Task
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo
  import Ecto.Query

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    from(t in Task, where: t.id == ^id)
    |> Repo.one()
    |> case do
      nil -> {:error, "Task not found"}
      task -> {:ok, task}
    end
  end

  def call(_id), do: {:error, "Task not found"}
end
