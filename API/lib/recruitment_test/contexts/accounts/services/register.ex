defmodule RecruitmentTest.Contexts.Accounts.Services.Register do
  @moduledoc """
  Service module responsible for registering a new user.
  """

  alias RecruitmentTest.Contexts.Accounts.User
  alias RecruitmentTest.Repo

  @spec call(attrs :: map()) :: {:ok, Ecto.Changeset.t()} | {:error, Ecto.Changeset.t()}
  def call(attrs) do
    user =
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()

    case user do
      {:ok, user} ->
        add_user_to_queue(user)
        {:ok, user}

      {:error, changeset} ->
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
