defmodule RecruitmentTest.Contexts.Enterprises.Services.Update do
  @moduledoc """
  Service module responsible for updating an existing enterprise's details.
  """
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo

  require Logger

  @spec call(
          id :: String.t(),
          attrs :: %{
            name: String.t() | nil,
            commercial_name: String.t() | nil,
            description: String.t() | nil
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def call(id, attrs) when is_uuid(id) do
    Logger.info("Updating enterprise", service: "enterprises.update", enterprise_id: id)

    with {:ok, enterprise} <- does_enterprise_exist(id),
         {:ok, updated_enterprise} <- update_enterprise(enterprise, attrs) do
      Logger.info("Enterprise updated successfully",
        service: "enterprises.update",
        enterprise_id: id
      )

      {:ok, updated_enterprise}
    else
      {:error, reason} = error ->
        Logger.warning("Enterprise update failed",
          service: "enterprises.update",
          enterprise_id: id,
          reason: inspect(reason)
        )

        error
    end
  end

  def call(_id, _attrs) do
    Logger.warning("Enterprise update failed - invalid ID", service: "enterprises.update")
    {:error, "Enterprise not found"}
  end

  defp does_enterprise_exist(id) do
    case RecruitmentTest.Contexts.Enterprises.Services.FindById.call(id) do
      {:ok, enterprise} -> {:ok, enterprise}
      {:error, _reason} -> {:error, "Enterprise not found"}
    end
  end

  defp update_enterprise(enterprise, attrs) do
    enterprise
    |> Enterprise.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, updated}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
