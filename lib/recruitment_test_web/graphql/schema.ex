defmodule RecruitmentTestWeb.Schema do
  use Absinthe.Schema

  import_types Absinthe.Type.Custom

  import_types RecruitmentTestWeb.Graphql.Types.Collaborator
  import_types RecruitmentTestWeb.Graphql.Types.Enterprise
  import_types RecruitmentTestWeb.Graphql.Types.Contract
  import_types RecruitmentTestWeb.Graphql.Types.Task
  import_types RecruitmentTestWeb.Graphql.Types.Report

  alias RecruitmentTestWeb.Graphql.Resolvers

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
    @desc "Get a collaborator by ID"
    field :collaborator, :collaborator do
      arg :id, non_null(:id)
      resolve &Resolvers.Collaborator.get_collaborator/3
    end

    @desc "List all collaborators"
    field :collaborators, list_of(:collaborator) do
      resolve &Resolvers.Collaborator.list_collaborators/3
    end

    @desc "Get an enterprise by ID"
    field :enterprise, :enterprise do
      arg :id, non_null(:id)
      resolve &Resolvers.Enterprise.get_enterprise/3
    end

    @desc "List all enterprises"
    field :enterprises, list_of(:enterprise) do
      resolve &Resolvers.Enterprise.list_enterprises/3
    end

    @desc "Get a contract by ID"
    field :contract, :contract do
      arg :id, non_null(:id)
      resolve &Resolvers.Contract.get_contract/3
    end

    @desc "List all contracts"
    field :contracts, list_of(:contract) do
      resolve &Resolvers.Contract.list_contracts/3
    end

    @desc "List contracts by enterprise ID"
    field :contracts_by_enterprise, list_of(:contract) do
      arg :enterprise_id, non_null(:id)
      resolve &Resolvers.Contract.list_contracts_by_enterprise/3
    end

    @desc "Get a task by ID"
    field :task, :task do
      arg :id, non_null(:id)
      resolve &Resolvers.Task.get_task/3
    end

    @desc "List all tasks"
    field :tasks, list_of(:task) do
      resolve &Resolvers.Task.list_tasks/3
    end

    @desc "Get a report by ID"
    field :report, :report do
      arg :id, non_null(:id)
      resolve &Resolvers.Report.get_report/3
    end

    @desc "List all reports"
    field :reports, list_of(:report) do
      resolve &Resolvers.Report.list_reports/3
    end
  end

  mutation do
    @desc "Create a new collaborator"
    field :create_collaborator, :collaborator do
      arg :input, non_null(:create_collaborator_input)
      resolve &Resolvers.Collaborator.create_collaborator/3
    end

    @desc "Update an existing collaborator"
    field :update_collaborator, :collaborator do
      arg :id, non_null(:id)
      arg :input, non_null(:update_collaborator_input)
      resolve &Resolvers.Collaborator.update_collaborator/3
    end

    @desc "Delete a collaborator"
    field :delete_collaborator, :delete_collaborator_response do
      arg :id, non_null(:id)
      resolve &Resolvers.Collaborator.delete_collaborator/3
    end

    # Enterprise mutations
    @desc "Create a new enterprise"
    field :create_enterprise, :enterprise do
      arg :input, non_null(:create_enterprise_input)
      resolve &Resolvers.Enterprise.create_enterprise/3
    end

    @desc "Update an existing enterprise"
    field :update_enterprise, :enterprise do
      arg :id, non_null(:id)
      arg :input, non_null(:update_enterprise_input)
      resolve &Resolvers.Enterprise.update_enterprise/3
    end

    @desc "Delete an enterprise"
    field :delete_enterprise, :delete_enterprise_response do
      arg :id, non_null(:id)
      resolve &Resolvers.Enterprise.delete_enterprise/3
    end

    # Contract mutations
    @desc "Create a new contract"
    field :create_contract, :contract do
      arg :input, non_null(:create_contract_input)
      resolve &Resolvers.Contract.create_contract/3
    end

    @desc "Update an existing contract"
    field :update_contract, :contract do
      arg :id, non_null(:id)
      arg :input, non_null(:update_contract_input)
      resolve &Resolvers.Contract.update_contract/3
    end

    @desc "Delete a contract"
    field :delete_contract, :delete_contract_response do
      arg :id, non_null(:id)
      resolve &Resolvers.Contract.delete_contract/3
    end

    # Task mutations
    @desc "Create a new task"
    field :create_task, :task do
      arg :input, non_null(:create_task_input)
      resolve &Resolvers.Task.create_task/3
    end

    @desc "Update an existing task"
    field :update_task, :task do
      arg :id, non_null(:id)
      arg :input, non_null(:update_task_input)
      resolve &Resolvers.Task.update_task/3
    end
  end
end
