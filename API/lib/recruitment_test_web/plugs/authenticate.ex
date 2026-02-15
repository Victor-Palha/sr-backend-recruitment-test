defmodule RecruitmentTestWeb.Plugs.Authenticate do
  @moduledoc """
  Plug to validate JWT access token and load the current user into the connection.
  """

  import Plug.Conn
  import Phoenix.Controller

  require Logger

  alias RecruitmentTest.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      Logger.info("Authentication successful",
        plug: "authenticate",
        user_id: user.id,
        user_role: user.role
      )

      conn
      |> assign(:current_user, user)
    else
      _ ->
        Logger.warning("Authentication failed - invalid or missing token",
          plug: "authenticate",
          path: conn.request_path
        )

        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized - Invalid or missing token"})
        |> halt()
    end
  end
end
