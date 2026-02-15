defmodule RecruitmentTest.Contexts.Accounts.Services.Register do
  @moduledoc """
  Service module responsible for registering a new user.
  """

  alias RecruitmentTest.Contexts.Accounts.User
  alias RecruitmentTest.Repo

  require Logger

  @spec call(attrs :: map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def call(attrs) do
    Logger.info("Registering new user",
      service: "accounts.register",
      email: attrs["email"] || attrs[:email]
    )

    case %User{} |> User.changeset(attrs) |> Repo.insert() do
      {:ok, user} ->
        Logger.info("User registered successfully",
          service: "accounts.register",
          user_id: user.id
        )

        add_user_to_queue(user)
        {:ok, user}

      {:error, changeset} ->
        Logger.warning("User registration failed",
          service: "accounts.register",
          errors: inspect(changeset.errors)
        )

        {:error, changeset}
    end
  end

  defp add_user_to_queue(user) do
    user
    |> Map.take([:id, :email, :name])
    |> Oban.Job.new(queue: :email, worker: RecruitmentTest.Jobs.WelcomeUser)
    |> Oban.insert()
  end
end
