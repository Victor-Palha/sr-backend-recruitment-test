defmodule RecruitmentTest.Contexts.Collaborators.Services.FindById do
  @moduledoc """
  Service module responsible for finding a collaborator by its ID.
  """

  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo
  import Ecto.Query

  @spec call(id :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    from(c in Collaborator, where: c.id == ^id)
    |> Repo.one()
    |> case do
      nil -> {:error, "Collaborator not found"}
      collaborator -> {:ok, collaborator}
    end
  end

  def call(_id), do: {:error, "Collaborator not found"}
end
