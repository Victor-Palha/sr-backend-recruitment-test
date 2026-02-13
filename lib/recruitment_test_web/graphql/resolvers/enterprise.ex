defmodule RecruitmentTestWeb.Graphql.Resolvers.Enterprise do
  @moduledoc """
  Resolver module for enterprise queries and mutations.
  """

  alias RecruitmentTest.Contexts.Enterprises.Services

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

  def list_enterprises(_parent, _args, _resolution) do
    {:ok, RecruitmentTest.Repo.all(RecruitmentTest.Contexts.Enterprises.Enterprise)}
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
