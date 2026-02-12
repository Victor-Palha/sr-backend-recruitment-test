defmodule RecruitmentTest.Contexts.Collaborators.Services.Update do
  @moduledoc """
  Service module responsible for updating an existing collaborator's details.
  """
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid
  alias RecruitmentTest.Repo

  @spec call(
          id :: String.t(),
          attrs :: %{
            name: String.t() | nil,
            email: String.t() | nil
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def call(id, attrs) when is_uuid(id) do
    with {:ok, collaborator} <- does_collaborator_exist(id),
         {:ok, updated_collaborator} <- update_collaborator(collaborator, attrs) do
      {:ok, updated_collaborator}
    end
  end

  def call(_id, _attrs), do: {:error, "Collaborator not found"}

  defp does_collaborator_exist(id) do
    case RecruitmentTest.Contexts.Collaborators.Services.FindById.call(id) do
      {:ok, collaborator} -> {:ok, collaborator}
      {:error, _reason} -> {:error, "Collaborator not found"}
    end
  end

  defp update_collaborator(collaborator, attrs) do
    collaborator
    |> Collaborator.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, updated}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
