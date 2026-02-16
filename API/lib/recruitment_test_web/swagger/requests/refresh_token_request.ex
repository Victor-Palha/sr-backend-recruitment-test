defmodule RecruitmentTestWeb.Swagger.Requests.RefreshTokenRequest do
  @moduledoc """
  Schema for refresh token request payload.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RefreshTokenRequest",
    description: "Request body for refreshing authentication tokens",
    type: :object,
    properties: %{
      refresh_token: %Schema{
        type: :string,
        description: "JWT refresh token"
      }
    },
    required: [:refresh_token],
    example: %{
      "refresh_token" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  })
end
