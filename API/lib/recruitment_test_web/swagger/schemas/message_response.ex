defmodule RecruitmentTestWeb.Swagger.Schemas.MessageResponse do
  @moduledoc """
  Schema for simple message responses.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "MessageResponse",
    description: "Success response with a message",
    type: :object,
    properties: %{
      message: %Schema{
        type: :string,
        description: "Success message"
      }
    },
    required: [:message],
    example: %{
      "message" => "Operation completed successfully"
    }
  })
end
