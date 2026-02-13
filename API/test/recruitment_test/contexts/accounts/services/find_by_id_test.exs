defmodule RecruitmentTest.Contexts.Accounts.Services.FindByIdTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Accounts.Services.FindById
  alias RecruitmentTest.Contexts.Accounts.User

  describe "call/1" do
    setup do
      {:ok, user} =
        %User{}
        |> User.changeset(%{
          name: "John Doe",
          email: "john@example.com",
          password: "Password123",
          role: "user"
        })
        |> Repo.insert()

      %{user: user}
    end

    test "finds a user by valid ID", %{user: user} do
      assert {:ok, %User{} = found_user} = FindById.call(user.id)
      assert found_user.id == user.id
      assert found_user.name == "John Doe"
      assert found_user.email == "john@example.com"
      assert found_user.role == "user"
      assert found_user.is_active == true
    end

    test "returns error when user does not exist" do
      non_existent_id = Ecto.UUID.generate()
      assert {:error, "User not found"} = FindById.call(non_existent_id)
    end

    test "finds admin user" do
      {:ok, admin} =
        %User{}
        |> User.changeset(%{
          name: "Admin User",
          email: "admin@example.com",
          password: "AdminPass123",
          role: "admin"
        })
        |> Repo.insert()

      assert {:ok, %User{} = found_admin} = FindById.call(admin.id)
      assert found_admin.role == "admin"
    end

    test "finds inactive user" do
      {:ok, inactive_user} =
        %User{}
        |> User.changeset(%{
          name: "Inactive User",
          email: "inactive@example.com",
          password: "Password123",
          role: "user",
          is_active: false
        })
        |> Repo.insert()

      assert {:ok, %User{} = found} = FindById.call(inactive_user.id)
      assert found.is_active == false
    end

    test "does not find soft deleted user" do
      {:ok, user} =
        %User{}
        |> User.changeset(%{
          name: "Deleted User",
          email: "deleted@example.com",
          password: "Password123",
          role: "user"
        })
        |> Repo.insert()

      user
      |> User.soft_delete_changeset()
      |> Repo.update()

      assert {:error, "User not found"} = FindById.call(user.id)
    end

    test "finds correct user when multiple exist", %{user: first_user} do
      {:ok, second_user} =
        %User{}
        |> User.changeset(%{
          name: "Jane Doe",
          email: "jane@example.com",
          password: "Password123",
          role: "user"
        })
        |> Repo.insert()

      assert {:ok, %User{} = found_first} = FindById.call(first_user.id)
      assert found_first.id == first_user.id
      assert found_first.name == "John Doe"

      assert {:ok, %User{} = found_second} = FindById.call(second_user.id)
      assert found_second.id == second_user.id
      assert found_second.name == "Jane Doe"
    end

    test "returns error with invalid UUID format" do
      assert {:error, "User not found"} = FindById.call("invalid-uuid")
      assert {:error, "User not found"} = FindById.call("123")
      assert {:error, "User not found"} = FindById.call(nil)
    end

    test "does not expose password or password hash", %{user: user} do
      {:ok, found_user} = FindById.call(user.id)

      assert found_user.password == nil

      assert found_user.password_hash != nil
      inspected = inspect(found_user)
      refute String.contains?(inspected, found_user.password_hash)
    end

    test "returns user with timestamps", %{user: user} do
      {:ok, found_user} = FindById.call(user.id)

      assert found_user.inserted_at
      assert found_user.updated_at
      assert NaiveDateTime.compare(found_user.inserted_at, found_user.updated_at) in [:lt, :eq]
    end

    test "finds user after email update", %{user: user} do
      user
      |> User.update_changeset(%{email: "newemail@example.com"})
      |> Repo.update()

      {:ok, found_user} = FindById.call(user.id)
      assert found_user.id == user.id
      assert found_user.email == "newemail@example.com"
    end

    test "finds user with all valid roles" do
      {:ok, regular_user} =
        %User{}
        |> User.changeset(%{
          name: "Regular User",
          email: "regular@example.com",
          password: "Password123",
          role: "user"
        })
        |> Repo.insert()

      {:ok, admin_user} =
        %User{}
        |> User.changeset(%{
          name: "Admin User",
          email: "admin@example.com",
          password: "Password123",
          role: "admin"
        })
        |> Repo.insert()

      assert {:ok, found_regular} = FindById.call(regular_user.id)
      assert found_regular.role == "user"

      assert {:ok, found_admin} = FindById.call(admin_user.id)
      assert found_admin.role == "admin"
    end
  end
end
