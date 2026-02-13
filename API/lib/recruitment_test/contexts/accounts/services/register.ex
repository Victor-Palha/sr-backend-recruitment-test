defmodule RecruitmentTest.Contexts.Accounts.Services.Register do
  @moduledoc """
  Service module responsible for registering a new user.
  """

  alias RecruitmentTest.Contexts.Accounts.User
  alias RecruitmentTest.Repo

  @spec call(attrs :: map()) :: {:ok, Ecto.Changeset.t()} | {:error, Ecto.Changeset.t()}
  def call(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
