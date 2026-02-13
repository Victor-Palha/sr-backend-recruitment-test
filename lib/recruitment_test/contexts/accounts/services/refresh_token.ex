defmodule RecruitmentTest.Contexts.Accounts.Services.RefreshToken do
  @moduledoc """
  Service module responsible for refreshing an access token using a refresh token.
  """

  alias RecruitmentTest.Contexts.Accounts.Token
  alias RecruitmentTest.Guardian
  alias RecruitmentTest.Repo
  import Ecto.Query

  @spec call(refresh_token :: String.t()) :: {:ok, map()} | {:error, String.t()}
  def call(refresh_token) do
    with {:ok, claims} <- Guardian.verify_token(refresh_token),
         {:ok, token_record} <- find_token_record(refresh_token),
         {:ok, token_record} <- verify_token_valid(token_record),
         {:ok, user} <- Guardian.resource_from_claims(claims),
         {:ok, token_data} <- Guardian.generate_tokens(user),
         {:ok, _} <- revoke_old_token(token_record),
         {:ok, _refresh_token} <- store_new_refresh_token(user, token_data) do
      {:ok,
       %{
         access_token: token_data.access_token,
         refresh_token: token_data.refresh_token
       }}
    end
  end

  defp find_token_record(token) do
    refresh_token_hash =
      RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(token)

    case Repo.one(from t in Token, where: t.token == ^refresh_token_hash and t.type == "refresh") do
      nil -> {:error, "Invalid refresh token"}
      token_record -> {:ok, token_record}
    end
  end

  defp verify_token_valid(token) do
    cond do
      Token.revoked?(token) -> {:error, "Token has been revoked"}
      Token.expired?(token) -> {:error, "Token has expired"}
      true -> {:ok, token}
    end
  end

  defp revoke_old_token(token) do
    token
    |> Token.revoke_changeset()
    |> Repo.update()
  end

  defp store_new_refresh_token(user, token_data) do
    expires_at = DateTime.from_unix!(token_data.refresh_claims["exp"])

    refresh_token_hash =
      RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(token_data.refresh_token)

    %Token{}
    |> Token.changeset(%{
      token: refresh_token_hash,
      type: "refresh",
      user_id: user.id,
      expires_at: expires_at
    })
    |> Repo.insert()
  end
end
