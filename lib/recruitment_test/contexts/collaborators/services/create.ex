defmodule RecruitmentTest.Contexts.Collaborators.Services.Create do
  @moduledoc """
  Service module responsible for creating a new collaborator.
  The collaborator's is created with is_active set to false by default.
  """
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Repo

  @spec call(
          attrs :: %{
            name: String.t(),
            email: String.t(),
            cpf: String.t()
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def call(attrs) do
    %Collaborator{}
    |> Collaborator.changeset(attrs)
    |> Repo.insert()
  end
end
