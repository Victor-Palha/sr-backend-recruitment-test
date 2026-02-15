defmodule RecruitmentTestWeb.Graphql.Types.Enterprise do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  @desc "Paginated enterprises result"
  object :paginated_enterprises do
    field(:data, non_null(list_of(non_null(:enterprise))))
    field(:page_info, non_null(:page_info))
  end

  @desc "An enterprise with its contracts"
  object :enterprise do
    field(:id, non_null(:id), description: "The unique identifier of the enterprise")
    field(:name, non_null(:string), description: "The legal name of the enterprise")

    field(:commercial_name, non_null(:string),
      description: "The commercial/trade name of the enterprise"
    )

    field(:cnpj, non_null(:string),
      description: "The CNPJ (Brazilian company registration number) of the enterprise"
    )

    field(:description, :string, description: "A description of the enterprise")

    @desc "All contracts associated with this enterprise, resolved using Dataloader for efficient batching"
    field :contracts, list_of(:contract) do
      resolve(dataloader(RecruitmentTest.Contexts.Content, :contracts, []))
    end

    field(:inserted_at, non_null(:naive_datetime), description: "When the enterprise was created")

    field(:updated_at, non_null(:naive_datetime),
      description: "When the enterprise was last updated"
    )
  end

  @desc "Enterprise filters"
  input_object :enterprise_filters do
    field(:name, :string)
    field(:cnpj, :string)
  end

  @desc "Input type for creating a new enterprise"
  input_object :create_enterprise_input do
    field(:cnpj, non_null(:string),
      description: "The CNPJ (Brazilian company registration number) of the enterprise"
    )

    field(:description, :string, description: "A description of the enterprise")
  end

  @desc "Input type for updating an existing enterprise"
  input_object :update_enterprise_input do
    field(:name, :string, description: "The legal name of the enterprise")
    field(:commercial_name, :string, description: "The commercial/trade name of the enterprise")
    field(:description, :string, description: "A description of the enterprise")
  end

  @desc "Response type for delete enterprise mutation"
  object :delete_enterprise_response do
    field(:success, non_null(:boolean), description: "Whether the deletion was successful")
    field(:enterprise, :enterprise, description: "The deleted enterprise")
  end
end
