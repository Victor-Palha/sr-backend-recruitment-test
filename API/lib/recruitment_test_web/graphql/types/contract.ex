defmodule RecruitmentTestWeb.Graphql.Types.Contract do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  @desc "Paginated contracts result"
  object :paginated_contracts do
    field(:data, non_null(list_of(non_null(:contract))))
    field(:page_info, non_null(:page_info))
  end

  @desc "Contract status enum"
  enum :contract_status do
    value(:active, as: "active", description: "Active contract")
    value(:expired, as: "expired", description: "Expired contract")
    value(:cancelled, as: "cancelled", description: "Cancelled contract")
  end

  @desc "A contract between an enterprise and a collaborator"
  object :contract do
    field(:id, non_null(:id), description: "The unique identifier of the contract")
    field(:value, :decimal, description: "The monetary value of the contract")
    field(:starts_at, non_null(:datetime), description: "When the contract starts")
    field(:expires_at, non_null(:datetime), description: "When the contract expires")

    field(:status, non_null(:contract_status), description: "The current status of the contract")

    @desc "The enterprise associated with this contract, resolved using Dataloader for efficient batching"
    field :enterprise, non_null(:enterprise) do
      resolve(dataloader(RecruitmentTest.Contexts.Content, :enterprise, []))
    end

    @desc "The collaborator associated with this contract, resolved using Dataloader for efficient batching"
    field :collaborator, non_null(:collaborator) do
      resolve(dataloader(RecruitmentTest.Contexts.Content, :collaborator, []))
    end

    field(:inserted_at, non_null(:datetime), description: "When the contract was created")
    field(:updated_at, non_null(:datetime), description: "When the contract was last updated")
  end

  @desc "Contract filters"
  input_object :contract_filters do
    field(:status, :contract_status)
    field(:enterprise_id, :id)
    field(:collaborator_id, :id)
  end

  @desc "Input type for creating a new contract"
  input_object :create_contract_input do
    field(:enterprise_id, non_null(:id), description: "The ID of the enterprise")
    field(:collaborator_id, non_null(:id), description: "The ID of the collaborator")
    field(:value, :decimal, description: "The monetary value of the contract")
    field(:starts_at, non_null(:datetime), description: "When the contract starts")
    field(:expires_at, non_null(:datetime), description: "When the contract expires")
    field(:status, :contract_status, description: "The status of the contract")
  end

  @desc "Input type for updating an existing contract"
  input_object :update_contract_input do
    field(:value, :decimal, description: "The monetary value of the contract")
    field(:starts_at, :datetime, description: "When the contract starts")
    field(:expires_at, :datetime, description: "When the contract expires")
    field(:status, :contract_status, description: "The status of the contract")
  end

  @desc "Response type for delete contract mutation"
  object :delete_contract_response do
    field(:success, non_null(:boolean), description: "Whether the deletion was successful")
    field(:contract, :contract, description: "The deleted contract")
  end
end
