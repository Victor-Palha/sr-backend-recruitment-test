defmodule RecruitmentTest.Utils.Validators.Cnpj.CnpjBehaviour do
  @moduledoc """
  Behaviour module defining the contract for CNPJ validation. This allows for different implementations (e.g., real API calls, mocks) to be used interchangeably in the application.
  """
  @type cnpj_response :: %{
          cnpj: String.t(),
          commercial_name: String.t(),
          name: String.t()
        }
  @callback validate(cnpj :: String.t()) :: {:ok, cnpj_response()} | {:error, String.t()}
end
