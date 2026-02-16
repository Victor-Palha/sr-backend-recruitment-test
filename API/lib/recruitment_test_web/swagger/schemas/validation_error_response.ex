defmodule RecruitmentTestWeb.Swagger.Schemas.ValidationErrorResponse do
  @moduledoc """
  Schema for validation error responses.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ValidationErrorResponse",
    description: "Response for validation errors with field-specific messages",
    type: :object,
    properties: %{
      errors: %Schema{
        type: :object,
        description: "Map of field names to error messages",
        additionalProperties: %Schema{
          oneOf: [
            %Schema{type: :string},
            %Schema{type: :array, items: %Schema{type: :string}}
          ]
        }
      }
    },
    required: [:errors],
    example: %{
      "errors" => %{
        "email" => "has already been taken",
        "password" => "should be at least 8 character(s)"
      }
    }
  })
end
