defmodule RecruitmentTestWeb.Swagger.Schemas.ErrorResponse do
  @moduledoc """
  Schema for error responses.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ErrorResponse",
    description: "Error response with error message",
    type: :object,
    properties: %{
      error: %Schema{
        type: :string,
        description: "Error message describing what went wrong"
      }
    },
    required: [:error],
    example: %{
      "error" => "Invalid credentials"
    }
  })
end
