defmodule RecruitmentTest.Contexts.Collaborators.Services.FindByCpf do
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Repo

  @spec call(cpf :: String.t()) :: {:ok, map()} | {:error, :not_found}
  def call(cpf) when is_binary(cpf) and byte_size(cpf) > 0 do
    case Repo.get_by(Collaborator, cpf: cpf) do
      nil -> {:error, :not_found}
      collaborator -> {:ok, collaborator}
    end
  end

  def call(_cpf), do: {:error, :not_found}
end
