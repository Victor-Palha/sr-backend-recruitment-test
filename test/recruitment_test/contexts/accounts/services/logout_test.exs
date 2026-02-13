defmodule RecruitmentTest.Contexts.Accounts.Services.LogoutTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Accounts.Services.{Login, Logout}
  alias RecruitmentTest.Contexts.Accounts.{User, Token}

  describe "call/1" do
    setup do
      {:ok, user} =
        %User{}
        |> User.changeset(%{
          name: "Test User",
          email: "test@example.com",
          password: "Password123",
          role: "user"
        })
        |> Repo.insert()

      {:ok, login_result} = Login.call("test@example.com", "Password123")

      %{user: user, refresh_token: login_result.refresh_token}
    end

    test "successfully revokes refresh token", %{user: user, refresh_token: refresh_token} do
      assert {:ok, "Successfully logged out"} = Logout.call(refresh_token)

      hashed_token =
        RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(refresh_token)

      token = Repo.get_by(Token, token: hashed_token, user_id: user.id)
      assert token.revoked_at != nil
      assert Token.revoked?(token)
    end

    test "returns error with invalid refresh token" do
      assert {:error, "Invalid refresh token"} = Logout.call("invalid_token_string")
    end

    test "returns error with non-existent refresh token" do
      {:ok, _user} =
        %User{}
        |> User.changeset(%{
          name: "Another User",
          email: "another@example.com",
          password: "Password123",
          role: "user"
        })
        |> Repo.insert()

      fake_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.fake.token"
      assert {:error, "Invalid refresh token"} = Logout.call(fake_token)
    end

    test "returns error when logging out with already revoked token", %{
      refresh_token: refresh_token
    } do
      assert {:ok, "Successfully logged out"} = Logout.call(refresh_token)

      assert {:error, "Invalid refresh token"} = Logout.call(refresh_token)
    end

    test "does not revoke access token (only refresh token)", %{
      user: user,
      refresh_token: refresh_token
    } do
      {:ok, login_result} = Login.call("test@example.com", "Password123")
      access_token = login_result.access_token

      assert {:ok, "Successfully logged out"} = Logout.call(refresh_token)

      {:ok, claims} = RecruitmentTest.Guardian.verify_token(access_token)
      {:ok, verified_user} = RecruitmentTest.Guardian.resource_from_claims(claims)
      assert verified_user.id == user.id
    end

    test "only revokes the specific refresh token, not all user tokens", %{user: user} do
      {:ok, login1} = Login.call("test@example.com", "Password123")
      {:ok, login2} = Login.call("test@example.com", "Password123")

      assert {:ok, "Successfully logged out"} = Logout.call(login1.refresh_token)

      hashed_token2 =
        RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(login2.refresh_token)

      token2 = Repo.get_by(Token, token: hashed_token2, user_id: user.id)
      assert token2.revoked_at == nil
      refute Token.revoked?(token2)
    end

    test "revoked token cannot be used for refresh", %{refresh_token: refresh_token} do
      assert {:ok, "Successfully logged out"} = Logout.call(refresh_token)

      alias RecruitmentTest.Contexts.Accounts.Services.RefreshToken
      assert {:error, "Token has been revoked"} = RefreshToken.call(refresh_token)
    end

    test "logout maintains token record in database", %{user: user, refresh_token: refresh_token} do
      initial_count = Repo.aggregate(from(t in Token, where: t.user_id == ^user.id), :count)

      assert {:ok, "Successfully logged out"} = Logout.call(refresh_token)

      final_count = Repo.aggregate(from(t in Token, where: t.user_id == ^user.id), :count)
      assert final_count == initial_count

      revoked_count =
        Repo.aggregate(
          from(t in Token, where: t.user_id == ^user.id and not is_nil(t.revoked_at)),
          :count
        )

      assert revoked_count > 0
    end

    test "user can login again after logout", %{refresh_token: refresh_token} do
      assert {:ok, "Successfully logged out"} = Logout.call(refresh_token)

      assert {:ok, new_login} = Login.call("test@example.com", "Password123")
      assert new_login.access_token
      assert new_login.refresh_token
      assert new_login.refresh_token != refresh_token
    end
  end
end
