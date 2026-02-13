defmodule RecruitmentTestWeb.AuthController do
  @moduledoc """
  Controller for handling authentication-related actions: login, logout, and token refresh.
  Provides endpoints for:
  - POST /api/auth/login: Authenticate user and return access and refresh tokens.
  - POST /api/auth/logout: Revoke the provided refresh token.
  - POST /api/auth/refresh: Refresh access token using a valid refresh token.
  """
  use RecruitmentTestWeb, :controller

  alias RecruitmentTest.Contexts.Accounts.Services.{Login, Logout, RefreshToken}

  def authenticate(conn, %{"email" => email, "password" => password}) do
    case Login.call(email, password) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}} ->
        conn
        |> put_status(:ok)
        |> json(%{
          access_token: access_token,
          refresh_token: refresh_token,
          message: "Successfully authenticated"
        })

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  def authenticate(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Email and password are required"})
  end

  def logout(conn, %{"refresh_token" => refresh_token}) do
    case Logout.call(refresh_token) do
      {:ok, message} ->
        conn
        |> put_status(:ok)
        |> json(%{message: message})

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  def logout(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Refresh token is required"})
  end

  def refresh(conn, %{"refresh_token" => refresh_token}) do
    case RefreshToken.call(refresh_token) do
      {:ok, %{access_token: access_token, refresh_token: new_refresh_token}} ->
        conn
        |> put_status(:ok)
        |> json(%{
          access_token: access_token,
          refresh_token: new_refresh_token,
          message: "Token refreshed successfully"
        })

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  def refresh(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Refresh token is required"})
  end
end
