defmodule RecruitmentTest.Contexts.Collaborators.Services.FindById do
  @moduledoc """
  Service module responsible for finding a collaborator by its ID.
  """

  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo
  import Ecto.Query

  require Logger

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    Logger.debug("Finding collaborator by ID", service: "collaborators.find_by_id", collaborator_id: id)

    from(c in Collaborator, where: c.id == ^id)
    |> Repo.one()
    |> case do
      nil ->
        Logger.debug("Collaborator not found", service: "collaborators.find_by_id", collaborator_id: id)
        {:error, "Collaborator not found"}

      collaborator ->
        {:ok, collaborator}
    end
  end

  def call(_id) do
    Logger.debug("Collaborator lookup with invalid ID", service: "collaborators.find_by_id")
    {:error, "Collaborator not found"}
  end
end
