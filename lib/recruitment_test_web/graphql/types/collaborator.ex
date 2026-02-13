defmodule RecruitmentTestWeb.Graphql.Types.Collaborator do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  @desc "A collaborator with their contracts, tasks, and reports"
  object :collaborator do
    field :id, non_null(:id), description: "The unique identifier of the collaborator"
    field :name, non_null(:string), description: "The full name of the collaborator"
    field :email, non_null(:string), description: "The email address of the collaborator"

    field :cpf, non_null(:string),
      description: "The CPF (Brazilian ID number) of the collaborator"

    field :is_active, non_null(:boolean), description: "Whether the collaborator is active"

    @desc "All contracts associated with this collaborator, resolved using Dataloader for efficient batching"
    field :contracts, list_of(:contract) do
      resolve dataloader(RecruitmentTest.Contexts.Content, :contracts, [])
    end

    # field :tasks, list_of(:task), description: "All tasks assigned to this collaborator"
    @desc "All tasks assigned to this collaborator, resolved using Dataloader for efficient batching"
    field :tasks, list_of(:task) do
      resolve dataloader(RecruitmentTest.Contexts.Content, :tasks, [])
    end

    @desc "All reports created by this collaborator, resolved using Dataloader for efficient batching"
    field :reports, list_of(:report) do
      resolve dataloader(RecruitmentTest.Contexts.Content, :reports, [])
    end

    field :inserted_at, non_null(:datetime), description: "When the collaborator was created"
    field :updated_at, non_null(:datetime), description: "When the collaborator was last updated"
  end

  @desc "Input type for creating a new collaborator"
  input_object :create_collaborator_input do
    field :name, non_null(:string), description: "The full name of the collaborator"
    field :email, non_null(:string), description: "The email address of the collaborator"

    field :cpf, non_null(:string),
      description: "The CPF (Brazilian ID number) of the collaborator"

    field :is_active, non_null(:boolean), description: "Whether the collaborator is active"
  end

  @desc "Input type for updating an existing collaborator"
  input_object :update_collaborator_input do
    field :name, :string, description: "The full name of the collaborator"
    field :email, :string, description: "The email address of the collaborator"
  end

  @desc "Response type for delete collaborator mutation"
  object :delete_collaborator_response do
    field :success, non_null(:boolean), description: "Whether the deletion was successful"
    field :collaborator, :collaborator, description: "The deleted collaborator"
  end
end
