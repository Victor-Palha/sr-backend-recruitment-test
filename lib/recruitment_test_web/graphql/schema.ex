defmodule RecruitmentTestWeb.Schema do
  use Absinthe.Schema

  import_types Absinthe.Type.Custom

  import_types RecruitmentTestWeb.Graphql.Types.Collaborator
  import_types RecruitmentTestWeb.Graphql.Types.Enterprise
  import_types RecruitmentTestWeb.Graphql.Types.Contract
  import_types RecruitmentTestWeb.Graphql.Types.Task
  import_types RecruitmentTestWeb.Graphql.Types.Report

  query do
    @desc "A simple health check test endpoint"
    field :health_check, :string do
      resolve fn _, _ -> {:ok, "OK"} end
    end
  end
end
