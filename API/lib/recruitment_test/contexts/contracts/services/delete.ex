defmodule RecruitmentTest.Contexts.Contracts.Services.Delete do
  @moduledoc """
  Service module responsible for soft deleting a contract by its ID.

  The contract is marked as cancelled rather than being removed from the database.
  If the collaborator has no other active contracts after deletion, they are also deactivated.
  """

  import Ecto.Query
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid

  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Contexts.Contracts.Contract
  alias RecruitmentTest.Repo

  require Logger

  @spec call(id :: String.t()) :: {:ok, Contract.t()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    Logger.info("Soft deleting contract", service: "contracts.delete", contract_id: id)

    with {:ok, contract} <- fetch_contract(id),
         {:ok, deleted_contract} <- deactivate_contract(contract) do
      Logger.info("Contract deleted successfully",
        service: "contracts.delete",
        contract_id: id
      )

      {:ok, deleted_contract}
    else
      {:error, reason} ->
        Logger.warning("Contract deletion failed",
          service: "contracts.delete",
          contract_id: id,
          reason: reason
        )

        {:error, reason}
    end
  end

  def call(_invalid_id) do
    Logger.warning("Contract deletion failed - invalid ID format",
      service: "contracts.delete"
    )

    {:error, "Contract not found"}
  end

  defp fetch_contract(id) do
    case Repo.get(Contract, id) do
      nil -> {:error, "Contract not found"}
      contract -> {:ok, contract}
    end
  end

  defp deactivate_contract(contract) do
    contract
    |> Contract.changeset(%{status: "cancelled"})
    |> Repo.update()
    |> case do
      {:ok, updated_contract} ->
        maybe_deactivate_collaborator(updated_contract.collaborator_id)
        {:ok, updated_contract}

      {:error, changeset} ->
        {:error, "Failed to deactivate contract: #{inspect(changeset.errors)}"}
    end
  end

  defp maybe_deactivate_collaborator(collaborator_id) do
    unless has_active_contracts?(collaborator_id) do
      deactivate_collaborator(collaborator_id)
    end
  end

  defp has_active_contracts?(collaborator_id) do
    Contract
    |> where([c], c.collaborator_id == ^collaborator_id)
    |> where([c], c.status == "active")
    |> Repo.exists?()
  end

  defp deactivate_collaborator(collaborator_id) do
    Collaborator
    |> where([c], c.id == ^collaborator_id)
    |> Repo.update_all(set: [is_active: false])

    Logger.info("Collaborator deactivated due to no active contracts",
      service: "contracts.delete",
      collaborator_id: collaborator_id
    )
  end
end
