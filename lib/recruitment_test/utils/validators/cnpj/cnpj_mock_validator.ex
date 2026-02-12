defmodule RecruitmentTest.Utils.Validators.Cnpj.CnpjMockValidator do
  @moduledoc """
  Mock implementation of the CNPJ validator for testing and development purposes.
  """
  @behaviour RecruitmentTest.Utils.Validators.Cnpj.CnpjBehaviour

  @impl true
  def validate(cnpj) when cnpj in ["00000000000000", "11111111111111"] do
    {:error, "CNPJ inválido"}
  end

  def validate(cnpj) do
    clean_cnpj = String.replace(cnpj, ~r/[^0-9]/, "")

    {:ok,
     %{
       cnpj: clean_cnpj,
       commercial_name: "EMPRESA TESTE LTDA",
       name: "Teste Corp"
     }}
  end
end
