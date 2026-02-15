defmodule RecruitmentTestWeb.UserController do
  use RecruitmentTestWeb, :controller

  require Logger

  alias RecruitmentTest.Contexts.Accounts.Services.Register

  plug(RecruitmentTestWeb.Plugs.Authenticate)
  plug(RecruitmentTestWeb.Plugs.RequireRole, roles: ["admin"])

  @doc """
  Creates a new user. Only accessible by admin users.
  """
  def create(
        conn,
        %{"name" => _name, "email" => email, "password" => _password, "role" => role} = params
      ) do
    Logger.info("User creation request",
      controller: "user",
      action: "create",
      email: email,
      role: role
    )

    case Register.call(params) do
      {:ok, user} ->
        Logger.info("User created successfully",
          controller: "user",
          action: "create",
          user_id: user.id
        )

        conn
        |> put_status(:created)
        |> json(%{
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          message: "User created successfully"
        })

      {:error, changeset} ->
        Logger.warning("User creation failed",
          controller: "user",
          action: "create",
          errors: inspect(changeset.errors)
        )

        errors = format_errors(changeset)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end

  def create(conn, params) do
    missing_fields =
      ["name", "email", "password", "role"]
      |> Enum.filter(fn field -> !Map.has_key?(params, field) end)

    Logger.warning("User creation failed - missing parameters #{inspect(missing_fields)}",
      controller: "user",
      action: "create"
    )

    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: #{Enum.join(missing_fields, ", ")}"})
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} ->
      msg
    end)
  end
end
