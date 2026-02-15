defmodule RecruitmentTest.Contexts.Enterprises.Services.FindByCnpj do
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Repo

  require Logger

  @spec call(cnpj :: String.t()) :: {:ok, map()} | {:error, :not_found}
  def call(cnpj) when is_binary(cnpj) and byte_size(cnpj) > 0 do
    Logger.debug("Finding enterprise by CNPJ", service: "enterprises.find_by_cnpj")

    case Repo.get_by(Enterprise, cnpj: cnpj) do
      nil -> {:error, :not_found}
      enterprise -> {:ok, enterprise}
    end
  end

  def call(_cnpj), do: {:error, :not_found}
end
