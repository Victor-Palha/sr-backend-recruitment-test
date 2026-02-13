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

    field :contracts, list_of(:contract),
      description: "All contracts associated with this enterprise"

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
end
