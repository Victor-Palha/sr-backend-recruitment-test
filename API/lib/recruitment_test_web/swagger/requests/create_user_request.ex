defmodule RecruitmentTestWeb.Swagger.Requests.CreateUserRequest do
  @moduledoc """
  Schema for create user request payload.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CreateUserRequest",
    description: "Request body for creating a new user (admin only)",
    type: :object,
    properties: %{
      name: %Schema{
        type: :string,
        description: "User full name"
      },
      email: %Schema{
        type: :string,
        format: :email,
        description: "User email address"
      },
      password: %Schema{
        type: :string,
        format: :password,
        description: "User password"
      },
      role: %Schema{
        type: :string,
        enum: ["admin", "user"],
        description: "User role in the system"
      }
    },
    required: [:name, :email, :password, :role],
    example: %{
      "name" => "Jane Smith",
      "email" => "jane.smith@example.com",
      "password" => "SecurePassword123!",
      "role" => "user"
    }
  })
end
