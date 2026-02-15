defmodule RecruitmentTest.Contexts.Contracts.Services.Update do
  @moduledoc """
  Service module responsible for updating an existing contract's details.
  """
  alias RecruitmentTest.Contexts.Contracts.Contract
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo

  require Logger

  @spec call(
          id :: String.t(),
          attrs :: %{
            value: Decimal.t() | nil,
            starts_at: DateTime.t() | nil,
            expires_at: DateTime.t() | nil,
            status: String.t() | nil
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def call(id, attrs) when is_uuid(id) do
    Logger.info("Updating contract", service: "contracts.update", contract_id: id)

    with {:ok, contract} <- does_contract_exist(id),
         {:ok, updated_contract} <- update_contract(contract, attrs) do
      Logger.info("Contract updated successfully", service: "contracts.update", contract_id: id)
      {:ok, updated_contract}
    else
      {:error, reason} = error ->
        Logger.warning("Contract update failed",
          service: "contracts.update",
          contract_id: id,
          reason: inspect(reason)
        )

        error
    end
  end

  def call(_id, _attrs) do
    Logger.warning("Contract update failed - invalid ID", service: "contracts.update")
    {:error, "Contract not found"}
  end

  defp does_contract_exist(id) do
    case Repo.get(Contract, id) do
      nil -> {:error, "Contract not found"}
      contract -> {:ok, contract}
    end
  end

  defp update_contract(contract, attrs) do
    contract
    |> Contract.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, updated}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
