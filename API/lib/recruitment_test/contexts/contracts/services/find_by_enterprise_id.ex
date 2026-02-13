defmodule RecruitmentTest.Contexts.Contracts.Services.FindByEnterpriseId do
  @moduledoc """
  Service module responsible for finding contracts by enterprise ID.
  """

  alias RecruitmentTest.Contexts.Contracts.Contract
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo
  import Ecto.Query

  @spec call(enterprise_id :: String.t()) :: list() | {:error, String.t()}
  def call(enterprise_id) when is_uuid(enterprise_id) do
    from(c in Contract, where: c.enterprise_id == ^enterprise_id)
    |> Repo.all()
  end

  def call(_id), do: {:error, "Enterprise not found"}
end
