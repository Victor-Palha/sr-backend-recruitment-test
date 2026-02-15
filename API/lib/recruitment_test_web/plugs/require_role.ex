defmodule RecruitmentTestWeb.Plugs.RequireRole do
  @moduledoc """
  Plug to validate that the current user has one of the required roles.
  Must be used after the Authenticate plug.
  """

  import Plug.Conn
  import Phoenix.Controller

  require Logger

  def init(opts) do
    roles = Keyword.get(opts, :roles, [])

    if roles == [] do
      raise ArgumentError, "RequireRole plug requires at least one role in :roles option"
    end

    roles
  end

  def call(conn, required_roles) do
    current_user = conn.assigns[:current_user]

    cond do
      is_nil(current_user) ->
        Logger.warning("Role check failed - user not authenticated",
          plug: "require_role",
          required_roles: inspect(required_roles)
        )

        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized - User not authenticated"})
        |> halt()

      current_user.role in required_roles ->
        Logger.debug("Role check passed",
          plug: "require_role",
          user_id: current_user.id,
          user_role: current_user.role,
          required_roles: inspect(required_roles)
        )

        conn

      true ->
        Logger.warning("Role check failed - insufficient permissions",
          plug: "require_role",
          user_id: current_user.id,
          user_role: current_user.role,
          required_roles: inspect(required_roles)
        )

        conn
        |> put_status(:forbidden)
        |> json(%{error: "Forbidden - Insufficient permissions"})
        |> halt()
    end
  end
end
