defmodule RecruitmentTest.Contexts.Accounts.Services.LoginTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Accounts.Services.Login
  alias RecruitmentTest.Contexts.Accounts.{User, Token}

  describe "call/2" do
    setup do
      {:ok, user} =
        %User{}
        |> User.changeset(%{
          name: "Test User",
          email: "test@example.com",
          password: "Password123",
          role: "user",
          is_active: true
        })
        |> Repo.insert()

      %{user: user}
    end

    test "successfully authenticates user with valid credentials", %{user: user} do
      assert {:ok, result} = Login.call("test@example.com", "Password123")

      assert result.access_token
      assert result.refresh_token
      assert result.user.id == user.id
      assert result.user.email == user.email

      token = Repo.get_by(Token, user_id: user.id, type: "refresh")
      assert token != nil
      assert token.expires_at != nil
      refute Token.expired?(token)
      refute Token.revoked?(token)
    end

    test "returns error with invalid email" do
      assert {:error, "Invalid credentials"} = Login.call("wrong@example.com", "Password123")
    end

    test "returns error with invalid password", %{user: _user} do
      assert {:error, "Invalid credentials"} = Login.call("test@example.com", "WrongPassword")
    end

    test "returns error when user is not active" do
      {:ok, _inactive_user} =
        %User{}
        |> User.changeset(%{
          name: "Inactive User",
          email: "inactive@example.com",
          password: "Password123",
          role: "user",
          is_active: false
        })
        |> Repo.insert()

      assert {:error, "User is not active"} =
               Login.call("inactive@example.com", "Password123")
    end

    test "returns error when user is soft deleted" do
      {:ok, deleted_user} =
        %User{}
        |> User.changeset(%{
          name: "Deleted User",
          email: "deleted@example.com",
          password: "Password123",
          role: "user"
        })
        |> Repo.insert()

      deleted_user
      |> User.soft_delete_changeset()
      |> Repo.update()

      assert {:error, "Invalid credentials"} = Login.call("deleted@example.com", "Password123")
    end

    test "generates different tokens for multiple logins", %{user: _user} do
      {:ok, result1} = Login.call("test@example.com", "Password123")
      {:ok, result2} = Login.call("test@example.com", "Password123")

      assert result1.access_token != result2.access_token
      assert result1.refresh_token != result2.refresh_token
    end

    test "stores hashed refresh token in database", %{user: user} do
      {:ok, result} = Login.call("test@example.com", "Password123")

      token_records = Repo.all(from t in Token, where: t.user_id == ^user.id)
      assert length(token_records) > 0

      Enum.each(token_records, fn record ->
        assert record.token != result.refresh_token
      end)
    end

    test "creates multiple token records for multiple logins", %{user: user} do
      {:ok, _result1} = Login.call("test@example.com", "Password123")
      {:ok, _result2} = Login.call("test@example.com", "Password123")

      tokens = Repo.all(from t in Token, where: t.user_id == ^user.id and t.type == "refresh")
      assert length(tokens) == 2
    end

    test "case insensitive email lookup" do
      assert {:ok, _result} = Login.call("TEST@EXAMPLE.COM", "Password123")
      assert {:ok, _result} = Login.call("TeSt@ExAmPlE.cOm", "Password123")
    end

    test "returns user data after successful login", %{user: user} do
      {:ok, result} = Login.call("test@example.com", "Password123")

      assert result.user.id == user.id
      assert result.user.name == "Test User"
      assert result.user.email == "test@example.com"
      assert result.user.role == "user"
      assert result.user.is_active == true
    end

    test "admin user can login", %{} do
      {:ok, _admin} =
        %User{}
        |> User.changeset(%{
          name: "Admin User",
          email: "admin@example.com",
          password: "AdminPass123",
          role: "admin"
        })
        |> Repo.insert()

      assert {:ok, result} = Login.call("admin@example.com", "AdminPass123")
      assert result.user.role == "admin"
    end
  end
end
