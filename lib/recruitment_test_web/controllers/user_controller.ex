defmodule RecruitmentTestWeb.UserController do
  use RecruitmentTestWeb, :controller

  alias RecruitmentTest.Contexts.Accounts.Services.Register

  plug RecruitmentTestWeb.Plugs.Authenticate
  plug RecruitmentTestWeb.Plugs.RequireRole, roles: ["admin"]

  @doc """
  Creates a new user. Only accessible by admin users.
  """
  def create(conn, params) do
    user_params = %{
      "name" => params["name"],
      "email" => params["email"],
      "password" => params["password"],
      "role" => params["role"] || "user"
    }

    case Register.call(user_params) do
      {:ok, user} ->
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
        errors = format_errors(changeset)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
