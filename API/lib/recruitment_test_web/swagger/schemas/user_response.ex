defmodule RecruitmentTestWeb.Swagger.Schemas.UserResponse do
  @moduledoc """
  Schema for user creation/update response.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UserResponse",
    description: "Response with user information",
    type: :object,
    properties: %{
      id: %Schema{
        type: :string,
        format: :uuid,
        description: "User ID"
      },
      name: %Schema{
        type: :string,
        description: "User name"
      },
      email: %Schema{
        type: :string,
        format: :email,
        description: "User email"
      },
      role: %Schema{
        type: :string,
        enum: ["admin", "user"],
        description: "User role"
      },
      message: %Schema{
        type: :string,
        description: "Success message"
      }
    },
    required: [:id, :name, :email, :role, :message],
    example: %{
      "id" => "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
      "name" => "Jane Smith",
      "email" => "jane.smith@example.com",
      "role" => "user",
      "message" => "User created successfully"
    }
  })
end
