defmodule RecruitmentTestWeb.Graphql.Middleware.Authorize do
  @moduledoc """
  Middleware to check if the current user has the required role(s).
  """

  @behaviour Absinthe.Middleware

  def call(resolution, role) do
    # Skip if there's already an error (e.g., from Authenticate middleware)
    if resolution.state == :resolved do
      resolution
    else
      with %{current_user: _user, role: user_role} <- resolution.context,
           true <- authorized?(user_role, role) do
        resolution
      else
        _ ->
          resolution
          |> Absinthe.Resolution.put_result({:error, "Forbidden - Insufficient permissions"})
      end
    end
  end

  defp authorized?(user_role, required_role) when is_binary(required_role) do
    user_role == required_role
  end

  defp authorized?(user_role, required_roles) when is_list(required_roles) do
    user_role in required_roles
  end
end
