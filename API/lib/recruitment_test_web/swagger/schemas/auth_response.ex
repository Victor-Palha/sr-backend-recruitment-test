defmodule RecruitmentTestWeb.Swagger.Schemas.AuthResponse do
  @moduledoc """
  Schema for authentication success response.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AuthResponse",
    description: "Successful authentication response with tokens and user info",
    type: :object,
    properties: %{
      access_token: %Schema{
        type: :string,
        description: "JWT access token for authenticated requests"
      },
      refresh_token: %Schema{
        type: :string,
        description: "JWT refresh token for obtaining new access tokens"
      },
      user: %Schema{
        type: :object,
        description: "Authenticated user information",
        properties: %{
          id: %Schema{type: :string, format: :uuid, description: "User ID"},
          name: %Schema{type: :string, description: "User name"},
          email: %Schema{type: :string, format: :email, description: "User email"},
          role: %Schema{type: :string, enum: ["admin", "user"], description: "User role"}
        }
      },
      message: %Schema{
        type: :string,
        description: "Success message"
      }
    },
    required: [:access_token, :refresh_token, :user, :message],
    example: %{
      "access_token" =>
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ...",
      "refresh_token" =>
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiZXhwIjoxNTE2MjM5MDIyfQ...",
      "user" => %{
        "id" => "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
        "name" => "John Doe",
        "email" => "john.doe@example.com",
        "role" => "user"
      },
      "message" => "Successfully authenticated"
    }
  })
end
