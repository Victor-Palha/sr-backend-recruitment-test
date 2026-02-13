defmodule RecruitmentTestWeb.Schema do
  use Absinthe.Schema

  import_types Absinthe.Type.Custom

  import_types RecruitmentTestWeb.Graphql.Types.Collaborator
  import_types RecruitmentTestWeb.Graphql.Types.Enterprise
  import_types RecruitmentTestWeb.Graphql.Types.Contract
  import_types RecruitmentTestWeb.Graphql.Types.Task
  import_types RecruitmentTestWeb.Graphql.Types.Report

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(
        RecruitmentTest.Contexts.Content,
        RecruitmentTest.Contexts.Content.data()
      )

    Map.put(ctx, :loader, loader)
  end

  query do
    @desc "A simple health check endpoint"
    field :health_check, :string do
      resolve fn _, _ -> {:ok, "OK"} end
    end
  end

  mutation do
    field :placeholder, :string do
      resolve fn _, _ -> {:ok, "placeholder"} end
    end
  end
end
