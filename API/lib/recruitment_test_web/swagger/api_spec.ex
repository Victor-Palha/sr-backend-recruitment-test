defmodule RecruitmentTestWeb.Swagger.ApiSpec do
  @moduledoc """
  OpenAPI specification for RecruitmentTest API.
  """

  alias OpenApiSpex.{Info, OpenApi, Paths, Server, Components, SecurityScheme}
  alias RecruitmentTestWeb.{Endpoint, Router}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "RecruitmentTest API",
        version: "1.0.0",
        description: "API for managing enterprise collaborators, contracts, tasks, and reports"
      },
      servers: [
        Server.from_endpoint(Endpoint)
      ],
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{
          "BearerAuth" => %SecurityScheme{
            type: "http",
            scheme: "bearer"
          }
        }
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
