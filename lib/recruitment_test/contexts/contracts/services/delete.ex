defmodule RecruitmentTest.Contexts.Contracts.Services.Delete do
  @moduledoc """
  Service module responsible for deleting a contract by its ID.
  """
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Contexts.Contracts.Contract
  alias RecruitmentTest.Repo
  import Ecto.Query

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    with {:ok, contract} <- does_contract_exist(id),
         {:ok, false} <- does_contract_has_tasks?(contract.id),
         {:ok, deleted_contract} <- delete_contract(contract) do
      {:ok, deleted_contract}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def call(_id), do: {:error, "Contract not found"}

  defp does_contract_exist(id) do
    case Repo.get(Contract, id) do
      nil -> {:error, "Contract not found"}
      contract -> {:ok, contract}
    end
  end

  defp does_contract_has_tasks?(contract_id) do
    collaborator_id =
      from(c in Contract, where: c.id == ^contract_id, select: c.collaborator_id)
      |> Repo.one()

    tasks_count =
      from(t in RecruitmentTest.Contexts.Tasks.Task, where: t.collaborator_id == ^collaborator_id)
      |> Repo.aggregate(:count)

    case tasks_count do
      0 -> {:ok, false}
      _ -> {:error, "Cannot delete contract with existing tasks for the collaborator"}
    end
  end

  defp delete_contract(contract) do
    case Repo.delete(contract) do
      {:ok, deleted_contract} -> {:ok, deleted_contract}
      {:error, reason} -> {:error, reason}
    end
  end
end
