defmodule RecruitmentTestWeb.Graphql.Resolvers.Report do
  @moduledoc """
  Resolver module for report queries.
  """

  alias RecruitmentTestWeb.Graphql.Helpers.PaginationHelper
  import Ecto.Query

  def get_report(_parent, %{id: id}, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Reports.Report,
      id
    )
    |> Dataloader.run()
    |> Dataloader.get(
      RecruitmentTest.Contexts.Content,
      RecruitmentTest.Contexts.Reports.Report,
      id
    )
    |> case do
      nil -> {:error, "Report not found"}
      report -> {:ok, report}
    end
  end

  def list_reports(_parent, args, _resolution) do
    RecruitmentTest.Contexts.Reports.Report
    |> PaginationHelper.apply_filters(args[:filters])
    |> order_by([r], desc: r.inserted_at)
    |> PaginationHelper.paginate(args)
  end
end
