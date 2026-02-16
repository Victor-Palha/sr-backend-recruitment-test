defmodule RecruitmentTestWeb.Swagger.Requests.LogoutRequest do
  @moduledoc """
  Schema for logout request payload.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LogoutRequest",
    description: "Request body for user logout",
    type: :object,
    properties: %{
      refresh_token: %Schema{
        type: :string,
        description: "JWT refresh token to invalidate"
      }
    },
    required: [:refresh_token],
    example: %{
      "refresh_token" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  })
end
