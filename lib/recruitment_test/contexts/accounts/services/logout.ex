defmodule RecruitmentTest.Contexts.Accounts.Services.Logout do
  @moduledoc """
  Service module responsible for revoking a user's refresh token.
  """

  alias RecruitmentTest.Contexts.Accounts.Token
  alias RecruitmentTest.Repo
  import Ecto.Query

  @spec call(refresh_token :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def call(refresh_token) do
    refresh_token_hash =
      RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(refresh_token)

    case Repo.one(from t in Token, where: t.token == ^refresh_token_hash and t.type == "refresh") do
      nil ->
        {:error, "Invalid refresh token"}

      token ->
        cond do
          Token.revoked?(token) ->
            {:error, "Invalid refresh token"}

          true ->
            token
            |> Token.revoke_changeset()
            |> Repo.update()
            |> case do
              {:ok, _} -> {:ok, "Successfully logged out"}
              {:error, _} -> {:error, "Failed to logout"}
            end
        end
    end
  end
end
