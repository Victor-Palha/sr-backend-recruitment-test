defmodule RecruitmentTest.Contexts.Accounts.Services.Logout do
  @moduledoc """
  Service module responsible for revoking a user's refresh token.
  """

  alias RecruitmentTest.Contexts.Accounts.Token
  alias RecruitmentTest.Repo
  import Ecto.Query

  require Logger

  @spec call(refresh_token :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def call(refresh_token) do
    Logger.info("Logout attempt", service: "accounts.logout")

    refresh_token_hash =
      RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(refresh_token)

    case Repo.one(from(t in Token, where: t.token == ^refresh_token_hash and t.type == "refresh")) do
      nil ->
        Logger.warning("Logout failed - invalid refresh token", service: "accounts.logout")
        {:error, "Invalid refresh token"}

      token ->
        cond do
          Token.revoked?(token) ->
            Logger.warning("Logout failed - token already revoked", service: "accounts.logout")
            {:error, "Invalid refresh token"}

          true ->
            token
            |> Token.revoke_changeset()
            |> Repo.update()
            |> case do
              {:ok, _} ->
                Logger.info("Logout successful",
                  service: "accounts.logout",
                  user_id: token.user_id
                )

                {:ok, "Successfully logged out"}

              {:error, _} ->
                Logger.error("Logout failed - database error", service: "accounts.logout")
                {:error, "Failed to logout"}
            end
        end
    end
  end
end
