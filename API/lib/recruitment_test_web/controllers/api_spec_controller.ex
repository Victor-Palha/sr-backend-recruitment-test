defmodule RecruitmentTestWeb.ApiSpecController do
  use RecruitmentTestWeb, :controller

  alias OpenApiSpex.Plug.PutApiSpec

  plug PutApiSpec, module: RecruitmentTestWeb.Swagger.ApiSpec

  def spec(conn, _params) do
    json(conn, RecruitmentTestWeb.Swagger.ApiSpec.spec())
  end
end
