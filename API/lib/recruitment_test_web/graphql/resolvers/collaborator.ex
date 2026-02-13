defmodule RecruitmentTestWeb.Graphql.Resolvers.Collaborator do
  @moduledoc """
  Resolver module for collaborator queries and mutations.
  """

  alias RecruitmentTest.Contexts.Collaborators.Services
  alias RecruitmentTestWeb.Graphql.Helpers.PaginationHelper
  import Ecto.Query

  def get_collaborator(_parent, %{id: id}, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Collaborators.Collaborator,
      id
    )
    |> Dataloader.run()
    |> Dataloader.get(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Collaborators.Collaborator,
      id
    )
    |> case do
      nil -> {:error, "Collaborator not found"}
      collaborator -> {:ok, collaborator}
    end
  end

  def list_collaborators(_parent, args, _resolution) do
    RecruitmentTest.Contexts.Collaborators.Collaborator
    |> PaginationHelper.apply_filters(args[:filters])
    |> order_by([c], c.name)
    |> PaginationHelper.paginate(args)
  end

  def create_collaborator(_parent, %{input: attrs}, _resolution) do
    Services.Create.call(attrs)
  end

  def update_collaborator(_parent, %{id: id, input: attrs}, _resolution) do
    Services.Update.call(id, attrs)
  end

  def delete_collaborator(_parent, %{id: id}, _resolution) do
    case Services.Delete.call(id) do
      {:ok, collaborator} -> {:ok, %{success: true, collaborator: collaborator}}
      {:error, reason} -> {:error, reason}
    end
  end
end
