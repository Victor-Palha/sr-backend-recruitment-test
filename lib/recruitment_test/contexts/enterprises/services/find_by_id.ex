defmodule RecruitmentTest.Contexts.Enterprises.Services.FindById do
  @moduledoc """
  Service module responsible for finding an enterprise by its ID.
  """

  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Repo
  import Ecto.Query

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) do
    from(e in Enterprise, where: e.id == ^id)
    |> Repo.one()
    |> case do
      nil -> {:error, "Enterprise not found"}
      enterprise -> {:ok, enterprise}
    end
  rescue
    Ecto.Query.CastError -> {:error, "Enterprise not found"}
    ArgumentError -> {:error, "Enterprise not found"}
  end
end
