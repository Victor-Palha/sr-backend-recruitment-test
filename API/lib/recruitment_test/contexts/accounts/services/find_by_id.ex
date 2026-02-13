defmodule RecruitmentTest.Contexts.Accounts.Services.FindById do
  @moduledoc """
  Service module responsible for finding a user by its ID.
  """

  alias RecruitmentTest.Contexts.Accounts.User
  alias RecruitmentTest.Repo
  import Ecto.Query
  import RecruitmentTest.Utils.Validators.Uuid.IsUuid

  @spec call(id :: String.t()) :: {:ok, Ecto.Changeset.t()} | {:error, String.t()}
  def call(id) when is_uuid(id) do
    from(u in User, where: u.id == ^id and is_nil(u.deleted_at))
    |> Repo.one()
    |> case do
      nil -> {:error, "User not found"}
      user -> {:ok, user}
    end
  end

  def call(_id), do: {:error, "User not found"}
end
