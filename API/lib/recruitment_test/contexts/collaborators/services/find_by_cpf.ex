defmodule RecruitmentTest.Contexts.Collaborators.Services.FindByCpf do
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Repo

  require Logger

  @spec call(cpf :: String.t()) :: {:ok, map()} | {:error, :not_found}
  def call(cpf) when is_binary(cpf) and byte_size(cpf) > 0 do
    Logger.debug("Finding collaborator by CPF", service: "collaborators.find_by_cpf")

    cpf = sanitize_cpf(cpf)

    case Repo.get_by(Collaborator, cpf: cpf) do
      nil -> {:error, :not_found}
      collaborator -> {:ok, collaborator}
    end
  end

  def call(_cpf), do: {:error, :not_found}

  defp sanitize_cpf(cpf) do
    cpf
    |> String.replace(~r/[^0-9]/, "")
  end
end
