defmodule RecruitmentTest.Contexts.Accounts.Services.FindById do
  @moduledoc """
  Service module responsible for finding a user by its ID.
  """

  alias RecruitmentTest.Contexts.Accounts.User
  alias RecruitmentTest.Repo
  import Ecto.Query
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid

  require Logger

  @spec call(id :: String.t()) :: {:ok, Ecto.Changeset.t()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    Logger.debug("Finding user by ID", service: "accounts.find_by_id", user_id: id)

    from(u in User, where: u.id == ^id and is_nil(u.deleted_at))
    |> Repo.one()
    |> case do
      nil ->
        Logger.debug("User not found", service: "accounts.find_by_id", user_id: id)
        {:error, "User not found"}

      user ->
        {:ok, user}
    end
  end

  def call(_id) do
    Logger.debug("User lookup with invalid ID", service: "accounts.find_by_id")
    {:error, "User not found"}
  end
end
