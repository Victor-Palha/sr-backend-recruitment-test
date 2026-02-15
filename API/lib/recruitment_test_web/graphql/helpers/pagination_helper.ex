defmodule RecruitmentTestWeb.Graphql.Helpers.PaginationHelper do
  @moduledoc """
  Helper functions for pagination in GraphQL queries.
  """

  import Ecto.Query

  @default_page_size 10
  @max_page_size 100

  @doc """
  Paginates a query with the given pagination arguments.
  """
  def paginate(query, args, repo \\ RecruitmentTest.Repo) do
    pagination = args[:pagination] || %{}
    page = Map.get(pagination, :page, 1)
    page_size = Map.get(pagination, :page_size, @default_page_size)

    page = max(1, page)
    page_size = min(max(1, page_size), @max_page_size)

    offset = (page - 1) * page_size

    total_count = repo.aggregate(query, :count)

    data =
      query
      |> limit(^page_size)
      |> offset(^offset)
      |> repo.all()

    total_pages = ceil(total_count / page_size)
    has_next_page = page < total_pages
    has_previous_page = page > 1

    {:ok,
     %{
       data: data,
       page_info: %{
         has_next_page: has_next_page,
         has_previous_page: has_previous_page,
         start_cursor: if(Enum.any?(data), do: to_string(offset + 1), else: nil),
         end_cursor: if(Enum.any?(data), do: to_string(offset + length(data)), else: nil),
         total_count: total_count
       }
     }}
  end

  @doc """
  Applies filters to a query based on the provided filter map.
  """
  def apply_filters(query, nil), do: query

  def apply_filters(query, filters) when is_map(filters) do
    Enum.reduce(filters, query, fn {key, value}, acc_query ->
      if is_nil(value) do
        acc_query
      else
        apply_filter(acc_query, key, value)
      end
    end)
  end

  # Collaborator and User filters
  defp apply_filter(query, :role, value) do
    where(query, [q], q.role == ^value)
  end

  defp apply_filter(query, :name, value) do
    where(query, [q], ilike(q.name, ^"%#{value}%"))
  end

  defp apply_filter(query, :email, value) do
    where(query, [q], ilike(q.email, ^"%#{value}%"))
  end

  defp apply_filter(query, :is_active, value) do
    where(query, [q], q.is_active == ^value)
  end

  # Enterprise filters
  defp apply_filter(query, :cnpj, value) do
    where(query, [q], ilike(q.cnpj, ^"%#{value}%"))
  end

  # Contract filters
  defp apply_filter(query, :status, value) do
    where(query, [q], q.status == ^value)
  end

  defp apply_filter(query, :enterprise_id, value) do
    where(query, [q], q.enterprise_id == ^value)
  end

  defp apply_filter(query, :collaborator_id, value) do
    where(query, [q], q.collaborator_id == ^value)
  end

  # Task filters
  defp apply_filter(query, :priority, value) do
    where(query, [q], q.priority == ^value)
  end

  # Report filters
  defp apply_filter(query, :task_id, value) do
    where(query, [q], q.task_id == ^value)
  end

  # Default: no filter applied
  defp apply_filter(query, _key, _value), do: query
end
