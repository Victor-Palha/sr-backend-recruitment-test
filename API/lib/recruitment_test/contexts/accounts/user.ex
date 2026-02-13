defmodule RecruitmentTest.Contexts.Accounts.User do
  use RecruitmentTest.Schema

  import Ecto.Changeset

  @valid_roles ~w(admin user)

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :is_active, :boolean, default: true
    field :role, :string
    field :deleted_at, :utc_datetime

    has_many :tokens, RecruitmentTest.Contexts.Accounts.Token

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :is_active, :role])
    |> validate_required([:name, :email, :password, :role])
    |> validate_email()
    |> validate_password()
    |> validate_role()
    |> hash_password()
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :is_active, :role])
    |> validate_email()
    |> validate_role()
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> hash_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 250)
    |> unsafe_validate_unique(:email, RecruitmentTest.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, ~r/[a-z]/,
      message: "must contain at least one lowercase letter"
    )
    |> validate_format(:password, ~r/[A-Z]/,
      message: "must contain at least one uppercase letter"
    )
    |> validate_format(:password, ~r/[0-9]/, message: "must contain at least one digit")
  end

  defp validate_role(changeset) do
    changeset
    |> validate_required([:role])
    |> validate_inclusion(:role, @valid_roles)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def verify_password(user, password) do
    Bcrypt.verify_pass(password, user.password_hash)
  end

  def soft_delete_changeset(user) do
    user
    |> change(deleted_at: DateTime.utc_now() |> DateTime.truncate(:second), is_active: false)
  end
end
