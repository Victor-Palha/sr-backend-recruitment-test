defmodule RecruitmentTest.Contexts.Collaborators.Services.Update do
  @moduledoc """
  Service module responsible for updating an existing collaborator's details.
  """
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo

  require Logger

  @spec call(
          id :: String.t(),
          attrs :: %{
            name: String.t() | nil,
            email: String.t() | nil
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def call(id, attrs) when is_uuid(id) do
    Logger.info("Updating collaborator", service: "collaborators.update", collaborator_id: id)

    with {:ok, collaborator} <- does_collaborator_exist(id),
         {:ok, updated_collaborator} <- update_collaborator(collaborator, attrs) do
      Logger.info("Collaborator updated successfully",
        service: "collaborators.update",
        collaborator_id: id
      )

      {:ok, updated_collaborator}
    else
      {:error, reason} = error ->
        Logger.warning("Collaborator update failed",
          service: "collaborators.update",
          collaborator_id: id,
          reason: inspect(reason)
        )

        error
    end
  end

  def call(_id, _attrs) do
    Logger.warning("Collaborator update failed - invalid ID", service: "collaborators.update")
    {:error, "Collaborator not found"}
  end

  defp does_collaborator_exist(id) do
    case RecruitmentTest.Contexts.Collaborators.Services.FindById.call(id) do
      {:ok, collaborator} -> {:ok, collaborator}
      {:error, _reason} -> {:error, "Collaborator not found"}
    end
  end

  defp update_collaborator(collaborator, attrs) do
    collaborator
    |> Collaborator.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, updated}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
