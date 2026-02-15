defmodule RecruitmentTestWeb.AuthController do
  @moduledoc """
  Controller for handling authentication-related actions: login, logout, and token refresh.
  """
  use RecruitmentTestWeb, :controller

  require Logger

  alias RecruitmentTest.Contexts.Accounts.Services.{Login, Logout, RefreshToken}

  def authenticate(conn, %{"email" => email, "password" => password}) do
    Logger.info("Authentication request",
      controller: "auth",
      action: "authenticate",
      email: email
    )

    case Login.call(email, password) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token, user: user}} ->
        Logger.info("Authentication successful",
          controller: "auth",
          action: "authenticate",
          email: email,
          user_id: user.id
        )

        conn
        |> put_status(:ok)
        |> json(%{
          access_token: access_token,
          refresh_token: refresh_token,
          user: %{
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
          },
          message: "Successfully authenticated"
        })

      {:error, reason} ->
        Logger.warning("Authentication failed",
          controller: "auth",
          action: "authenticate",
          email: email,
          reason: reason
        )

        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  def authenticate(conn, _params) do
    Logger.warning("Authentication request with missing params",
      controller: "auth",
      action: "authenticate"
    )

    conn
    |> put_status(:bad_request)
    |> json(%{error: "Email and password are required"})
  end

  def logout(conn, %{"refresh_token" => refresh_token}) do
    Logger.info("Logout request", controller: "auth", action: "logout")

    case Logout.call(refresh_token) do
      {:ok, message} ->
        Logger.info("Logout successful", controller: "auth", action: "logout")

        conn
        |> put_status(:ok)
        |> json(%{message: message})

      {:error, reason} ->
        Logger.warning("Logout failed", controller: "auth", action: "logout", reason: reason)

        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  def logout(conn, _params) do
    Logger.warning("Logout request with missing params", controller: "auth", action: "logout")

    conn
    |> put_status(:bad_request)
    |> json(%{error: "Refresh token is required"})
  end

  def refresh(conn, %{"refresh_token" => refresh_token}) do
    Logger.info("Token refresh request", controller: "auth", action: "refresh")

    case RefreshToken.call(refresh_token) do
      {:ok, %{access_token: access_token, refresh_token: new_refresh_token}} ->
        Logger.info("Token refresh successful", controller: "auth", action: "refresh")

        conn
        |> put_status(:ok)
        |> json(%{
          access_token: access_token,
          refresh_token: new_refresh_token,
          message: "Token refreshed successfully"
        })

      {:error, reason} ->
        Logger.warning("Token refresh failed",
          controller: "auth",
          action: "refresh",
          reason: reason
        )

        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  def refresh(conn, _params) do
    Logger.warning("Token refresh request with missing params",
      controller: "auth",
      action: "refresh"
    )

    conn
    |> put_status(:bad_request)
    |> json(%{error: "Refresh token is required"})
  end
end
