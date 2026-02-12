defmodule RecruitmentTest.Contexts.Collaborators.Services.Delete do
  @moduledoc """
  Service module responsible for soft-deleting a collaborator by setting is_active to false.
  """
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Repo

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    with {:ok, collaborator} <- does_collaborator_exist(id),
         {:ok, deactivated_collaborator} <- deactivate_collaborator(collaborator) do
      {:ok, deactivated_collaborator}
    end
  end

  def call(_id), do: {:error, "Collaborator not found"}

  defp does_collaborator_exist(id) do
    case RecruitmentTest.Contexts.Collaborators.Services.FindById.call(id) do
      {:ok, collaborator} -> {:ok, collaborator}
      {:error, _reason} -> {:error, "Collaborator not found"}
    end
  end

  defp deactivate_collaborator(collaborator) do
    collaborator
    |> Collaborator.deactivate_changeset()
    |> Repo.update()
    |> case do
      {:ok, updated_collaborator} -> {:ok, updated_collaborator}
      {:error, _changeset} -> {:error, "Failed to deactivate collaborator"}
    end
  end
end
