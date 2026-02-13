defmodule RecruitmentTest.Contexts.Contracts.Services.FindById do
  @moduledoc """
  Service module responsible for finding a contract by its ID.
  """

  alias RecruitmentTest.Contexts.Contracts.Contract
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo
  import Ecto.Query

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    from(c in Contract, where: c.id == ^id)
    |> Repo.one()
    |> case do
      nil -> {:error, "Contract not found"}
      contract -> {:ok, contract}
    end
  end

  def call(_id), do: {:error, "Contract not found"}
end
