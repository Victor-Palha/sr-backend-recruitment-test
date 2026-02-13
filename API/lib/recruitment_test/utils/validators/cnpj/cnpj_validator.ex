defmodule RecruitmentTest.Utils.Validators.Cnpj.CnpjValidator do
  @moduledoc """
  Implementation of the CNPJ validator that interacts with an external API to validate and retrieve information about a CNPJ.
  """
  @behaviour RecruitmentTest.Utils.Validators.Cnpj.CnpjBehaviour

  @base_url "https://brasilapi.com.br/api"

  @impl true
  def validate(cnpj) do
    clean_cnpj = String.replace(cnpj, ~r/[^0-9]/, "")

    "#{@base_url}/cnpj/v1/#{clean_cnpj}"
    |> HTTPoison.get()
    |> handle_response()
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    case Jason.decode(body) do
      {:ok, data} -> {:ok, parse_response(data)}
      {:error, _} -> {:error, "Erro ao decodificar resposta da API"}
    end
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 404}}) do
    {:error, "CNPJ não encontrado"}
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: status}}) do
    {:error, "Erro na API: status #{status}"}
  end

  defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, "Erro ao consultar CNPJ: #{inspect(reason)}"}
  end

  defp parse_response(data) do
    %{
      cnpj: data["cnpj"],
      commercial_name: data["razao_social"],
      name: data["nome_fantasia"]
    }
  end
end
