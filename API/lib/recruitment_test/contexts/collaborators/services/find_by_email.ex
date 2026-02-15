defmodule RecruitmentTest.Contexts.Collaborators.Services.FindByEmail do
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Repo

  require Logger

  @spec call(email :: String.t()) :: {:ok, map()} | {:error, :not_found}
  def call(email) when is_binary(email) and byte_size(email) > 0 do
    Logger.debug("Finding collaborator by email", service: "collaborators.find_by_email")

    case Repo.get_by(Collaborator, email: email) do
      nil -> {:error, :not_found}
      collaborator -> {:ok, collaborator}
    end
  end

  def call(_email), do: {:error, :not_found}
end
