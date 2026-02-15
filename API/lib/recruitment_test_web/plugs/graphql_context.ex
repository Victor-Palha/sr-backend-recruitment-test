defmodule RecruitmentTestWeb.Plugs.GraphQLContext do
  @moduledoc """
  Plug to build GraphQL context with current user and role information.
  Extracts JWT token from Authorization header and adds user to context.
  """

  @behaviour Plug

  require Logger

  alias RecruitmentTest.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    existing_context = conn.private[:absinthe][:context] || %{}

    context =
      if Map.has_key?(existing_context, :current_user) do
        existing_context
      else
        build_context(conn)
      end

    Logger.debug("GraphQL context built",
      plug: "graphql_context",
      authenticated: Map.has_key?(context, :current_user)
    )

    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    with ["Bearer " <> token] <- Plug.Conn.get_req_header(conn, "authorization"),
         {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      %{current_user: user, role: user.role}
    else
      _ -> %{}
    end
  end
end
