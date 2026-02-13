defmodule RecruitmentTestWeb.Graphql.Types.Contract do
  use Absinthe.Schema.Notation

  @desc "Contract status enum"
  enum :contract_status do
    value :active, description: "Active contract"
    value :expired, description: "Expired contract"
    value :cancelled, description: "Cancelled contract"
  end

  @desc "A contract between an enterprise and a collaborator"
  object :contract do
    field :id, non_null(:id), description: "The unique identifier of the contract"
    field :value, :decimal, description: "The monetary value of the contract"
    field :starts_at, non_null(:datetime), description: "When the contract starts"
    field :expires_at, non_null(:datetime), description: "When the contract expires"

    field :status, non_null(:contract_status), description: "The current status of the contract"

    @desc "The enterprise associated with this contract, resolved using Dataloader for efficient batching"
    field :enterprise, non_null(:enterprise) do
      resolve(Absinthe.Resolution.Helpers.dataloader(RecruitmentTest.Contexts.Content))
    end

    @desc "The collaborator associated with this contract, resolved using Dataloader for efficient batching"
    field :collaborator, non_null(:collaborator) do
      resolve(Absinthe.Resolution.Helpers.dataloader(RecruitmentTest.Contexts.Content))
    end

    field :inserted_at, non_null(:datetime), description: "When the contract was created"
    field :updated_at, non_null(:datetime), description: "When the contract was last updated"
  end

  @desc "Input type for creating a new contract"
  input_object :create_contract_input do
    field :enterprise_id, non_null(:id), description: "The ID of the enterprise"
    field :collaborator_id, non_null(:id), description: "The ID of the collaborator"
    field :value, :decimal, description: "The monetary value of the contract"
    field :starts_at, non_null(:datetime), description: "When the contract starts"
    field :expires_at, non_null(:datetime), description: "When the contract expires"
    field :status, :contract_status, description: "The status of the contract"
  end

  @desc "Input type for updating an existing contract"
  input_object :update_contract_input do
    field :value, :decimal, description: "The monetary value of the contract"
    field :starts_at, :datetime, description: "When the contract starts"
    field :expires_at, :datetime, description: "When the contract expires"
    field :status, :contract_status, description: "The status of the contract"
  end

  @desc "Response type for delete contract mutation"
  object :delete_contract_response do
    field :success, non_null(:boolean), description: "Whether the deletion was successful"
    field :contract, :contract, description: "The deleted contract"
  end
end
