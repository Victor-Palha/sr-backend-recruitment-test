defmodule RecruitmentTest.Contexts.Accounts.Services.Login do
  @moduledoc """
  Service module responsible for authenticating a user and generating tokens.
  """

  alias RecruitmentTest.Contexts.Accounts.{User, Token}
  alias RecruitmentTest.Guardian
  alias RecruitmentTest.Repo
  import Ecto.Query

  require Logger

  @spec call(email :: String.t(), password :: String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def call(email, password) do
    Logger.info("Login attempt", service: "accounts.login", email: email)

    with {:ok, user} <- find_user_by_email(email),
         {:ok, user} <- verify_user_active(user),
         {:ok, user} <- verify_password(user, password),
         {:ok, tokens} <- generate_and_store_tokens(user) do
      Logger.info("Login successful", service: "accounts.login", user_id: user.id)

      response = %{
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        user: user
      }

      {:ok, response}
    else
      {:error, reason} = error ->
        Logger.warning("Login failed", service: "accounts.login", email: email, reason: reason)
        error
    end
  end

  defp find_user_by_email(email) do
    email_lower = String.downcase(email)

    case Repo.one(from(u in User, where: u.email == ^email_lower and is_nil(u.deleted_at))) do
      nil -> {:error, "Invalid credentials"}
      user -> {:ok, user}
    end
  end

  defp verify_user_active(%User{is_active: false}), do: {:error, "User is not active"}
  defp verify_user_active(user), do: {:ok, user}

  defp verify_password(user, password) do
    if User.verify_password(user, password) do
      {:ok, user}
    else
      {:error, "Invalid credentials"}
    end
  end

  defp generate_and_store_tokens(user) do
    with {:ok, token_data} <- Guardian.generate_tokens(user),
         {:ok, _refresh_token} <- store_refresh_token(user, token_data) do
      {:ok,
       %{
         access_token: token_data.access_token,
         refresh_token: token_data.refresh_token,
         user: user
       }}
    end
  end

  defp store_refresh_token(user, token_data) do
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
