defmodule RecruitmentTest.Contexts.Accounts.Token do
  use RecruitmentTest.Schema

  import Ecto.Changeset

  @valid_types ~w(refresh access)

  schema "tokens" do
    field :token, :string
    field :type, :string
    field :expires_at, :utc_datetime
    field :revoked_at, :utc_datetime

    belongs_to :user, RecruitmentTest.Contexts.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:token, :type, :user_id, :expires_at])
    |> validate_required([:token, :type, :user_id, :expires_at])
    |> validate_inclusion(:type, @valid_types)
    |> unique_constraint(:token)
    |> foreign_key_constraint(:user_id)
  end

  def revoke_changeset(token) do
    token
    |> change(revoked_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def expired?(token) do
    DateTime.compare(token.expires_at, DateTime.utc_now()) == :lt
  end

  def revoked?(token) do
    not is_nil(token.revoked_at)
  end

  def valid?(token) do
    !expired?(token) && !revoked?(token)
  end
end
