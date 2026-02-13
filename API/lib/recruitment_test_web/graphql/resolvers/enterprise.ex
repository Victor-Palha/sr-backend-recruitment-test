defmodule RecruitmentTestWeb.Graphql.Resolvers.Enterprise do
  @moduledoc """
  Resolver module for enterprise queries and mutations.
  """

  alias RecruitmentTest.Contexts.Enterprises.Services
  alias RecruitmentTestWeb.Graphql.Helpers.PaginationHelper
  import Ecto.Query

  def get_enterprise(_parent, %{id: id}, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Enterprises.Enterprise,
      id
    )
    |> Dataloader.run()
    |> Dataloader.get(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Enterprises.Enterprise,
      id
    )
    |> case do
      nil -> {:error, "Enterprise not found"}
      enterprise -> {:ok, enterprise}
    end
  end

  def list_enterprises(_parent, args, _resolution) do
    RecruitmentTest.Contexts.Enterprises.Enterprise
    |> PaginationHelper.apply_filters(args[:filters])
    |> order_by([e], e.name)
    |> PaginationHelper.paginate(args)
  end

  def create_enterprise(_parent, %{input: attrs}, _resolution) do
    Services.Create.call(attrs)
  end

  def update_enterprise(_parent, %{id: id, input: attrs}, _resolution) do
    Services.Update.call(id, attrs)
  end

  def delete_enterprise(_parent, %{id: id}, _resolution) do
    case Services.Delete.call(id) do
      {:ok, enterprise} -> {:ok, %{success: true, enterprise: enterprise}}
      {:error, reason} -> {:error, reason}
    end
  end
end
