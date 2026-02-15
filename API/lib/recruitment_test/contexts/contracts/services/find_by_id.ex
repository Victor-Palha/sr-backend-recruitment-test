defmodule RecruitmentTest.Contexts.Contracts.Services.FindById do
  @moduledoc """
  Service module responsible for finding a contract by its ID.
  """

  alias RecruitmentTest.Contexts.Contracts.Contract
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo
  import Ecto.Query

  require Logger

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    Logger.debug("Finding contract by ID", service: "contracts.find_by_id", contract_id: id)

    from(c in Contract, where: c.id == ^id)
    |> Repo.one()
    |> case do
      nil ->
        Logger.debug("Contract not found", service: "contracts.find_by_id", contract_id: id)
        {:error, "Contract not found"}

      contract ->
        {:ok, contract}
    end
  end

  def call(_id) do
    Logger.debug("Contract lookup with invalid ID", service: "contracts.find_by_id")
    {:error, "Contract not found"}
  end
end
