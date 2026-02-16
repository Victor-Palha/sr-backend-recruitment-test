defmodule RecruitmentTestWeb.Swagger.Schemas.User do
  @moduledoc """
  This module defines the Swagger schema for the User resource in the RecruitmentTestWeb application.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "User",
    description: "A user in the system",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid, description: "User ID"},
      email: %Schema{type: :string, format: :email, description: "User email address"},
      name: %Schema{type: :string, description: "User name"},
      role: %Schema{
        type: :string,
        enum: ["admin", "user"],
        description: "User role"
      },
      is_active: %Schema{type: :boolean, description: "Whether user is active"},
      created_at: %Schema{
        type: :string,
        format: :"date-time",
        description: "User creation timestamp"
      },
      updated_at: %Schema{
        type: :string,
        format: :"date-time",
        description: "User last update timestamp"
      },
      deleted_at: %Schema{
        type: :string,
        format: :"date-time",
        description: "User deletion timestamp (if soft-deleted)"
      }
    },
    required: [:id, :email, :name, :role, :is_active, :created_at, :updated_at],
    example: %{
      "id" => "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
      "email" => "user@example.com",
      "name" => "John Doe",
      "role" => "user",
      "is_active" => true,
      "created_at" => "2026-02-08T03:00:00Z",
      "updated_at" => "2026-02-08T03:00:00Z",
      "deleted_at" => nil
    }
  })
end
