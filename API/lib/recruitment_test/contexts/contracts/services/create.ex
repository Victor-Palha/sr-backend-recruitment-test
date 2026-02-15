defmodule RecruitmentTest.Contexts.Contracts.Services.Create do
  @moduledoc """
  Service module responsible for creating a new contract between an enterprise and a collaborator.
  """
  alias RecruitmentTest.Contexts.Contracts.Contract
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Repo

  require Logger

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
    Logger.info("Creating contract",
      service: "contracts.create",
      enterprise_id: attrs[:enterprise_id],
      collaborator_id: attrs[:collaborator_id]
    )

    with {:ok, enterprise_id} <- get_enterprise_id(attrs),
         {:ok, collaborator_id} <- get_collaborator_id(attrs),
         {:ok, _enterprise} <- does_enterprise_exist(enterprise_id),
         {:ok, collaborator} <- does_collaborator_exist(collaborator_id),
         {:ok, contract} <- insert_contract(attrs),
         {:ok, _collaborator} <- activate_collaborator(collaborator) do
      Logger.info("Contract created successfully",
        service: "contracts.create",
        contract_id: contract.id
      )

      {:ok, contract}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.warning("Contract creation failed - validation error",
          service: "contracts.create",
          errors: inspect(changeset.errors)
        )

        {:error, changeset}

      {:error, "Enterprise not found"} ->
        Logger.warning("Contract creation failed - enterprise not found",
          service: "contracts.create"
        )

        {:error, "Enterprise not found"}

      {:error, "Collaborator not found"} ->
        Logger.warning("Contract creation failed - collaborator not found",
          service: "contracts.create"
        )

        {:error, "Collaborator not found"}

      {:error, reason} ->
        Logger.warning("Contract creation failed",
          service: "contracts.create",
          reason: inspect(reason)
        )

        {:error, reason}
    end
  end

  defp get_enterprise_id(%{enterprise_id: enterprise_id}), do: {:ok, enterprise_id}
  defp get_enterprise_id(_), do: {:error, "Enterprise not found"}

  defp get_collaborator_id(%{collaborator_id: collaborator_id}), do: {:ok, collaborator_id}
  defp get_collaborator_id(_), do: {:error, "Collaborator not found"}

  defp does_enterprise_exist(enterprise_id) do
    case RecruitmentTest.Contexts.Enterprises.Services.FindById.call(enterprise_id) do
      {:ok, enterprise} -> {:ok, enterprise}
      {:error, _reason} -> {:error, "Enterprise not found"}
    end
  end

  defp does_collaborator_exist(collaborator_id) do
    case RecruitmentTest.Contexts.Collaborators.Services.FindById.call(collaborator_id) do
      {:ok, collaborator} -> {:ok, collaborator}
      {:error, _reason} -> {:error, "Collaborator not found"}
    end
  end

  defp insert_contract(attrs) do
    %Contract{}
    |> Contract.changeset(attrs)
    |> Repo.insert()
  end

  defp activate_collaborator(%Collaborator{} = collaborator) do
    collaborator
    |> Collaborator.changeset(%{is_active: true})
    |> Repo.update()
  end
end
