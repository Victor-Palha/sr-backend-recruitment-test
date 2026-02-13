defmodule RecruitmentTestWeb.Graphql.Resolvers.Report do
  @moduledoc """
  Resolver module for report queries.
  """

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

  def list_reports(_parent, _args, _resolution) do
    {:ok, RecruitmentTest.Repo.all(RecruitmentTest.Contexts.Reports.Report)}
  end
end
