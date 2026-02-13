defmodule RecruitmentTest.Contexts.Accounts.Services.RegisterTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Accounts.Services.Register
  alias RecruitmentTest.Contexts.Accounts.User

  describe "call/1" do
    test "creates a user successfully with valid data" do
      attrs = %{
        name: "John Doe",
        email: "john@example.com",
        password: "Password123",
        role: "user"
      }

      assert {:ok, %User{} = user} = Register.call(attrs)
      assert user.name == "John Doe"
      assert user.email == "john@example.com"
      assert user.role == "user"
      assert user.is_active == true
      assert user.password_hash != nil
      assert user.password == nil
      assert user.id
      assert user.inserted_at
      assert user.updated_at
    end

    test "creates an admin user" do
      attrs = %{
        name: "Admin User",
        email: "admin@example.com",
        password: "AdminPass123",
        role: "admin"
      }

      assert {:ok, %User{} = user} = Register.call(attrs)
      assert user.role == "admin"
    end

    test "creates an inactive user when specified" do
      attrs = %{
        name: "Inactive User",
        email: "inactive@example.com",
        password: "Password123",
        role: "user",
        is_active: false
      }

      assert {:ok, %User{} = user} = Register.call(attrs)
      assert user.is_active == false
    end

    test "hashes the password" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        password: "MySecret123",
        role: "user"
      }

      assert {:ok, %User{} = user} = Register.call(attrs)
      assert user.password_hash != "MySecret123"
      assert String.starts_with?(user.password_hash, "$2b$")
    end

    test "returns error when name is missing" do
      attrs = %{
        email: "test@example.com",
        password: "Password123",
        role: "user"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error when email is missing" do
      attrs = %{
        name: "Test User",
        password: "Password123",
        role: "user"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "can't be blank" in errors_on(changeset).email
    end

    test "returns error when password is missing" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        role: "user"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "can't be blank" in errors_on(changeset).password
    end

    test "returns error when role is missing" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        password: "Password123"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "can't be blank" in errors_on(changeset).role
    end

    test "returns error when email is invalid format" do
      attrs = %{
        name: "Test User",
        email: "invalid-email",
        password: "Password123",
        role: "user"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "must be a valid email" in errors_on(changeset).email
    end

    test "returns error when email already exists" do
      existing_attrs = %{
        name: "Existing User",
        email: "duplicate@example.com",
        password: "Password123",
        role: "user"
      }

      assert {:ok, _user} = Register.call(existing_attrs)

      new_attrs = %{
        name: "New User",
        email: "duplicate@example.com",
        password: "DifferentPass123",
        role: "user"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(new_attrs)
      assert "has already been taken" in errors_on(changeset).email
    end

    test "returns error when password is too short" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        password: "Short1",
        role: "user"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "returns error when password has no lowercase letter" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        password: "PASSWORD123",
        role: "user"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "must contain at least one lowercase letter" in errors_on(changeset).password
    end

    test "returns error when password has no uppercase letter" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        password: "password123",
        role: "user"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "must contain at least one uppercase letter" in errors_on(changeset).password
    end

    test "returns error when password has no digit" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        password: "PasswordOnly",
        role: "user"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "must contain at least one digit" in errors_on(changeset).password
    end

    test "returns error when role is invalid" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        password: "Password123",
        role: "superuser"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs)
      assert "is invalid" in errors_on(changeset).role
    end

    test "email is case insensitive for uniqueness" do
      attrs1 = %{
        name: "User One",
        email: "test@EXAMPLE.com",
        password: "Password123",
        role: "user"
      }

      attrs2 = %{
        name: "User Two",
        email: "TEST@example.com",
        password: "Password123",
        role: "user"
      }

      assert {:ok, _user} = Register.call(attrs1)
      assert {:error, %Ecto.Changeset{} = changeset} = Register.call(attrs2)
      assert "has already been taken" in errors_on(changeset).email
    end
  end
end
