defmodule RecruitmentTestWeb.HealthController do
  @moduledoc """
  Just an endpoint to check if the API is up and running.
  Is especially useful for health checks by load balancers or container orchestrators.
  """
  use RecruitmentTestWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "healthy"})
  end
end
