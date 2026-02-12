defmodule RecruitmentTest.Contexts.Contracts.Services.Create do
  @moduledoc """
  Service module responsible for creating a new contract between an enterprise and a collaborator.
  """
  alias RecruitmentTest.Contexts.Contracts.Contract
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Repo

  import Ecto.Query

  @spec call(
          attrs :: %{
            enterprise_id: String.t(),
            collaborator_id: String.t(),
            starts_at: Date.t(),
            expires_at: Date.t(),
            value: Decimal.t() | nil,
            status: String.t() | nil
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def call(attrs) do
    with {:ok, enterprise_id} <- get_enterprise_id(attrs),
         {:ok, collaborator_id} <- get_collaborator_id(attrs),
         true <- does_enterprise_exist?(enterprise_id),
         true <- does_collaborator_exist?(collaborator_id),
         {:ok, contract} <- insert_contract(attrs),
         {:ok, _collaborator} <- activate_collaborator(collaborator_id) do
      {:ok, contract}
    else
      false -> {:error, "Enterprise or Collaborator not found"}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_enterprise_id(%{enterprise_id: enterprise_id}), do: {:ok, enterprise_id}
  defp get_enterprise_id(_), do: {:error, "Enterprise or Collaborator not found"}

  defp get_collaborator_id(%{collaborator_id: collaborator_id}), do: {:ok, collaborator_id}
  defp get_collaborator_id(_), do: {:error, "Enterprise or Collaborator not found"}

  defp does_enterprise_exist?(enterprise_id) do
    from(e in Enterprise, where: e.id == ^enterprise_id)
    |> Repo.exists?()
  end

  defp does_collaborator_exist?(collaborator_id) do
    from(c in Collaborator, where: c.id == ^collaborator_id)
    |> Repo.exists?()
  end

  defp insert_contract(attrs) do
    %Contract{}
    |> Contract.changeset(attrs)
    |> Repo.insert()
  end

  defp activate_collaborator(collaborator_id) do
    collaborator = Repo.get!(Collaborator, collaborator_id)

    collaborator
    |> Collaborator.changeset(%{is_active: true})
    |> Repo.update()
  end
end
