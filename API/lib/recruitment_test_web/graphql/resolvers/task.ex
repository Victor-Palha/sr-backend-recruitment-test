defmodule RecruitmentTestWeb.Graphql.Resolvers.Task do
  @moduledoc """
  Resolver module for task queries and mutations.
  """

  alias RecruitmentTest.Contexts.Tasks.Services
  alias RecruitmentTestWeb.Graphql.Helpers.PaginationHelper
  import Ecto.Query

  def get_task(_parent, %{id: id}, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(RecruitmentTest.Contexts.Content, RecruitmentTest.Contexts.Tasks.Task, id)
    |> Dataloader.run()
    |> Dataloader.get(RecruitmentTest.Contexts.Content, RecruitmentTest.Contexts.Tasks.Task, id)
    |> case do
      nil -> {:error, "Task not found"}
      task -> {:ok, task}
    end
  end

  def list_tasks(_parent, args, _resolution) do
    RecruitmentTest.Contexts.Tasks.Task
    |> PaginationHelper.apply_filters(args[:filters])
    |> order_by([t], asc: t.priority, desc: t.inserted_at)
    |> PaginationHelper.paginate(args)
  end

  def create_task(_parent, %{input: attrs}, _resolution) do
    Services.Create.call(attrs)
  end

  def update_task(_parent, %{id: id, input: attrs}, _resolution) do
    Services.Update.call(id, attrs)
  end
end
