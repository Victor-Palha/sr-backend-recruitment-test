defmodule RecruitmentTest.Contexts.Collaborators.Services.Delete do
  @moduledoc """
  Service module responsible for soft-deleting a collaborator by setting is_active to false.
  """
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Repo

  require Logger

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    Logger.info("Deactivating collaborator", service: "collaborators.delete", collaborator_id: id)

    with {:ok, collaborator} <- does_collaborator_exist(id),
         {:ok, deactivated_collaborator} <- deactivate_collaborator(collaborator) do
      Logger.info("Collaborator deactivated successfully",
        service: "collaborators.delete",
        collaborator_id: id
      )

      {:ok, deactivated_collaborator}
    else
      {:error, reason} ->
        Logger.warning("Collaborator deactivation failed",
          service: "collaborators.delete",
          collaborator_id: id,
          reason: reason
        )

        {:error, reason}
    end
  end

  def call(_id) do
    Logger.warning("Collaborator deactivation failed - invalid ID",
      service: "collaborators.delete"
    )

    {:error, "Collaborator not found"}
  end

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
