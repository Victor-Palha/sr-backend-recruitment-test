defmodule RecruitmentTestWeb.Graphql.Middleware.Authenticate do
  @moduledoc """
  Middleware to ensure the user is authenticated.
  Must be used before Authorize middleware.
  """

  @behaviour Absinthe.Middleware

  def call(resolution, _config) do
    case resolution.context do
      %{current_user: _user} ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "Unauthorized - Invalid or missing token"})
    end
  end
end
