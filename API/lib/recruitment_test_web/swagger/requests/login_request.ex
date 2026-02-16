defmodule RecruitmentTestWeb.Swagger.Requests.LoginRequest do
  @moduledoc """
  Schema for login request payload.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LoginRequest",
    description: "Request body for user authentication",
    type: :object,
    properties: %{
      email: %Schema{
        type: :string,
        format: :email,
        description: "User email address"
      },
      password: %Schema{
        type: :string,
        format: :password,
        description: "User password"
      }
    },
    required: [:email, :password],
    example: %{
      "email" => "user@example.com",
      "password" => "SecurePassword123!"
    }
  })
end
