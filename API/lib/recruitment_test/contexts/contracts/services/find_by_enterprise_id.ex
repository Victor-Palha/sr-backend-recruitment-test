defmodule RecruitmentTest.Contexts.Contracts.Services.FindByEnterpriseId do
  @moduledoc """
  Service module responsible for finding contracts by enterprise ID.
  """

  alias RecruitmentTest.Contexts.Contracts.Contract
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo
  import Ecto.Query

  require Logger

  @spec call(enterprise_id :: String.t()) :: list() | {:error, String.t()}
  def call(enterprise_id) when is_uuid(enterprise_id) do
    Logger.debug("Finding contracts by enterprise ID", service: "contracts.find_by_enterprise_id", enterprise_id: enterprise_id)

    from(c in Contract, where: c.enterprise_id == ^enterprise_id)
    |> Repo.all()
  end

  def call(_id) do
    Logger.debug("Contract lookup with invalid enterprise ID", service: "contracts.find_by_enterprise_id")
    {:error, "Enterprise not found"}
  end
end
