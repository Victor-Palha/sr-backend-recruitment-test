defmodule RecruitmentTestWeb.AuthController do
  @moduledoc """
  Controller for handling authentication-related actions: login, logout, and token refresh.
  """
  use RecruitmentTestWeb, :controller
  use OpenApiSpex.ControllerSpecs

  require Logger

  alias RecruitmentTest.Contexts.Accounts.Services.{Login, Logout, RefreshToken}
  alias RecruitmentTestWeb.Swagger.Requests
  alias RecruitmentTestWeb.Swagger.Schemas

  tags(["Authentication"])

  operation(:authenticate,
    summary: "Login",
    description: "Authenticates a user and returns JWT tokens and user info.",
    request_body:
      {"Login credentials", "application/json", Requests.LoginRequest, required: true},
    responses: [
      ok: {"Success", "application/json", Schemas.AuthResponse},
      unauthorized: {"Invalid credentials", "application/json", Schemas.ErrorResponse},
      bad_request: {"Missing parameters", "application/json", Schemas.ErrorResponse}
    ]
  )

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

  operation(:logout,
    summary: "Logout",
    description: "Invalidates a refresh token and logs out the user.",
    request_body: {"Logout request", "application/json", Requests.LogoutRequest, required: true},
    responses: [
      ok: {"Success", "application/json", Schemas.MessageResponse},
      unauthorized: {"Invalid or expired token", "application/json", Schemas.ErrorResponse},
      bad_request: {"Missing refresh token", "application/json", Schemas.ErrorResponse}
    ]
  )

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

  operation(:refresh,
    summary: "Refresh Token",
    description: "Refreshes the access token using a valid refresh token.",
    request_body:
      {"Refresh token request", "application/json", Requests.RefreshTokenRequest, required: true},
    responses: [
      ok: {"Success", "application/json", Schemas.TokenResponse},
      unauthorized: {"Invalid or expired token", "application/json", Schemas.ErrorResponse},
      bad_request: {"Missing refresh token", "application/json", Schemas.ErrorResponse}
    ]
  )

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
