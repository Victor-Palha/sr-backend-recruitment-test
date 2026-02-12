defmodule RecruitmentTest.Contexts.Enterprises.Services.Delete do
  @moduledoc """
  Service module responsible for deleting an enterprise by its ID.
  """
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    with {:ok, enterprise} <- does_enterprise_exist(id),
         {:ok, false} <- does_enterprise_has_contracts?(enterprise.id),
         {:ok, deleted_enterprise} <- delete_enterprise(enterprise) do
      {:ok, deleted_enterprise}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def call(_id), do: {:error, "Enterprise not found"}

  defp does_enterprise_exist(id) do
    case RecruitmentTest.Contexts.Enterprises.Services.FindById.call(id) do
      {:ok, enterprise} -> {:ok, enterprise}
      {:error, _reason} -> {:error, "Enterprise not found"}
    end
  end

  defp does_enterprise_has_contracts?(enterprise_id) do
    contracts = RecruitmentTest.Contexts.Contracts.Services.FindByEnterpriseId.call(enterprise_id)

    case contracts do
      [] -> {:ok, false}
      _ -> {:error, "Cannot delete enterprise with existing contracts"}
    end
  end

  defp delete_enterprise(enterprise) do
    case Repo.delete(enterprise) do
      {:ok, deleted_enterprise} -> {:ok, deleted_enterprise}
      {:error, reason} -> {:error, reason}
    end
  end
end
