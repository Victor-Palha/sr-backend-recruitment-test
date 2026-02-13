defmodule RecruitmentTestWeb.Graphql.Resolvers.Contract do
  @moduledoc """
  Resolver module for contract queries and mutations.
  """

  alias RecruitmentTest.Contexts.Contracts.Services

  def get_contract(_parent, %{id: id}, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Contracts.Contract,
      id
    )
    |> Dataloader.run()
    |> Dataloader.get(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Contracts.Contract,
      id
    )
    |> case do
      nil -> {:error, "Contract not found"}
      contract -> {:ok, contract}
    end
  end

  def list_contracts(_parent, _args, _resolution) do
    {:ok, RecruitmentTest.Repo.all(RecruitmentTest.Contexts.Contracts.Contract)}
  end

  def list_contracts_by_enterprise(_parent, %{enterprise_id: enterprise_id}, _resolution) do
    Services.FindByEnterpriseId.call(enterprise_id)
  end

  def create_contract(_parent, %{input: attrs}, _resolution) do
    Services.Create.call(attrs)
  end

  def update_contract(_parent, %{id: id, input: attrs}, _resolution) do
    Services.Update.call(id, attrs)
  end

  def delete_contract(_parent, %{id: id}, _resolution) do
    case Services.Delete.call(id) do
      {:ok, contract} -> {:ok, %{success: true, contract: contract}}
      {:error, reason} -> {:error, reason}
    end
  end
end
