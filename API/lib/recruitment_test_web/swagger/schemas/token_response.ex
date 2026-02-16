defmodule RecruitmentTestWeb.Swagger.Schemas.TokenResponse do
  @moduledoc """
  Schema for token refresh response.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TokenResponse",
    description: "Response with new access and refresh tokens",
    type: :object,
    properties: %{
      access_token: %Schema{
        type: :string,
        description: "New JWT access token"
      },
      refresh_token: %Schema{
        type: :string,
        description: "New JWT refresh token"
      },
      message: %Schema{
        type: :string,
        description: "Success message"
      }
    },
    required: [:access_token, :refresh_token, :message],
    example: %{
      "access_token" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "message" => "Token refreshed successfully"
    }
  })
end
