defmodule RecruitmentTest.Contexts.Enterprises.Services.Create do
  @moduledoc """
  Service module responsible for creating a new enterprise.
  """
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Repo
  @cnpj_validator Application.compile_env(:recruitment_test, :cnpj_validator)

  @spec call(
          attrs :: %{
            cnpj: String.t(),
            description: String.t() | nil
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def call(attrs) do
    with {:ok, cnpj_data} <- validate_cnpj(attrs.cnpj),
         merged_attrs <- merge_cnpj_data(attrs, cnpj_data),
         {:ok, _} <- enterprise_with_same_cnpj_exists?(cnpj_data.cnpj),
         {:ok, enterprise} <- insert_enterprise(merged_attrs) do
      {:ok, enterprise}
    else
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  defp validate_cnpj(cnpj) do
    case @cnpj_validator.validate(cnpj) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, "Invalid CNPJ: #{reason}"}
    end
  end

  defp merge_cnpj_data(attrs, cnpj_data) do
    Map.merge(attrs, %{
      cnpj: cnpj_data.cnpj,
      name: cnpj_data.name,
      commercial_name: cnpj_data.commercial_name
    })
  end

  defp enterprise_with_same_cnpj_exists?(cnpj) do
    RecruitmentTest.Contexts.Enterprises.Services.FindByCnpj.call(cnpj)
    |> case do
      {:ok, _enterprise} -> {:error, "An enterprise with this CNPJ already exists"}
      {:error, _reason} -> {:ok, false}
    end
  end

  defp insert_enterprise(attrs) do
    %Enterprise{}
    |> Enterprise.changeset(attrs)
    |> Repo.insert()
  end
end
