defmodule RecruitmentTestWeb.Graphql.Resolvers.User do
  @moduledoc """
  Resolver module for user queries and mutations.
  """
  alias RecruitmentTestWeb.Graphql.Helpers.PaginationHelper
  import Ecto.Query

  def get_user(_parent, %{id: id}, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Accounts.User,
      id
    )
    |> Dataloader.run()
    |> Dataloader.get(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Accounts.User,
      id
    )
    |> case do
      nil ->
        {:error, "User not found"}

      user ->
        {:ok, user}
    end
  end

  def list_users(_parent, args, _resolution) do
    RecruitmentTest.Contexts.Accounts.User
    |> PaginationHelper.apply_filters(args[:filters])
    |> order_by([u], u.name)
    |> PaginationHelper.paginate(args)
  end
end
