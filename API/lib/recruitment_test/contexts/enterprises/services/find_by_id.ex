defmodule RecruitmentTest.Contexts.Enterprises.Services.FindById do
  @moduledoc """
  Service module responsible for finding an enterprise by its ID.
  """

  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo
  import Ecto.Query

  require Logger

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    Logger.debug("Finding enterprise by ID", service: "enterprises.find_by_id", enterprise_id: id)

    from(e in Enterprise, where: e.id == ^id)
    |> Repo.one()
    |> case do
      nil ->
        Logger.debug("Enterprise not found", service: "enterprises.find_by_id", enterprise_id: id)
        {:error, "Enterprise not found"}

      enterprise ->
        {:ok, enterprise}
    end
  end

  def call(_id) do
    Logger.debug("Enterprise lookup with invalid ID", service: "enterprises.find_by_id")
    {:error, "Enterprise not found"}
  end
end
