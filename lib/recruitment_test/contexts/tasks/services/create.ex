defmodule RecruitmentTest.Contexts.Tasks.Services.Create do
  @moduledoc """
  Service module responsible for creating a new task for a collaborator.
  """

  alias RecruitmentTest.Contexts.Tasks.Task
  alias RecruitmentTest.Repo

  @spec call(
          attrs :: %{
            name: String.t(),
            description: String.t() | nil,
            status: String.t() | nil,
            priority: number() | nil,
            collaborator_id: String.t()
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def call(attrs) do
    with {:ok, collaborator} <- does_collaborator_exist(attrs),
         {:ok, true} <- is_collaborator_active?(collaborator) do
      insert_task(attrs)
    else
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  defp does_collaborator_exist(%{collaborator_id: collaborator_id}) do
    case RecruitmentTest.Contexts.Collaborators.Services.FindById.call(collaborator_id) do
      {:ok, collaborator} -> {:ok, collaborator}
      {:error, _reason} -> {:error, "Collaborator not found"}
    end
  end

  defp does_collaborator_exist(_), do: {:error, "Collaborator not found"}

  defp is_collaborator_active?(collaborator) do
    case collaborator.is_active do
      true -> {:ok, true}
      false -> {:error, "Collaborator is not active"}
    end
  end

  defp insert_task(attrs) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end
end
