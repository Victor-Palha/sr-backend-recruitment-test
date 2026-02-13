defmodule RecruitmentTestWeb.Graphql.Types.Enterprise do
  use Absinthe.Schema.Notation

  @desc "An enterprise with its contracts"
  object :enterprise do
    field :id, non_null(:id), description: "The unique identifier of the enterprise"
    field :name, non_null(:string), description: "The legal name of the enterprise"

    field :commercial_name, non_null(:string),
      description: "The commercial/trade name of the enterprise"

    field :cnpj, non_null(:string),
      description: "The CNPJ (Brazilian company registration number) of the enterprise"

    field :description, :string, description: "A description of the enterprise"

    @desc "All contracts associated with this enterprise, resolved using Dataloader for efficient batching"
    field :contracts, list_of(:contract) do
      resolve(Absinthe.Resolution.Helpers.dataloader(RecruitmentTest.Contexts.Content))
    end

    field :inserted_at, non_null(:datetime), description: "When the enterprise was created"
    field :updated_at, non_null(:datetime), description: "When the enterprise was last updated"
  end

  @desc "Input type for creating a new enterprise"
  input_object :create_enterprise_input do
    field :name, non_null(:string), description: "The legal name of the enterprise"

    field :commercial_name, non_null(:string),
      description: "The commercial/trade name of the enterprise"

    field :cnpj, non_null(:string),
      description: "The CNPJ (Brazilian company registration number) of the enterprise"

    field :description, :string, description: "A description of the enterprise"
  end

  @desc "Input type for updating an existing enterprise"
  input_object :update_enterprise_input do
    field :name, :string, description: "The legal name of the enterprise"
    field :commercial_name, :string, description: "The commercial/trade name of the enterprise"
    field :description, :string, description: "A description of the enterprise"
  end

  @desc "Response type for delete enterprise mutation"
  object :delete_enterprise_response do
    field :success, non_null(:boolean), description: "Whether the deletion was successful"
    field :enterprise, :enterprise, description: "The deleted enterprise"
  end
end
