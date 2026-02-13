defmodule RecruitmentTestWeb.Graphql.Resolvers.Contract do
  @moduledoc """
  Resolver module for contract queries and mutations.
  """

  alias RecruitmentTest.Contexts.Contracts.Services
  alias RecruitmentTestWeb.Graphql.Helpers.PaginationHelper
  import Ecto.Query

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

  def list_contracts(_parent, args, _resolution) do
    RecruitmentTest.Contexts.Contracts.Contract
    |> PaginationHelper.apply_filters(args[:filters])
    |> order_by([c], desc: c.inserted_at)
    |> PaginationHelper.paginate(args)
  end

  def list_contracts_by_enterprise(_parent, %{enterprise_id: enterprise_id}, _resolution) do
    case Services.FindByEnterpriseId.call(enterprise_id) do
      {:error, _reason} = error -> error
      contracts when is_list(contracts) -> {:ok, contracts}
    end
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
