defmodule RecruitmentTest.Contexts.Accounts.Services.RefreshTokenTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Accounts.Services.{Login, RefreshToken}
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

    test "successfully refreshes token with valid refresh token", %{
      user: user,
      refresh_token: refresh_token
    } do
      assert {:ok, result} = RefreshToken.call(refresh_token)

      assert result.access_token
      assert result.refresh_token
      assert result.access_token != refresh_token
      assert result.refresh_token != refresh_token

      hashed_old_token =
        RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(refresh_token)

      old_token = Repo.get_by(Token, token: hashed_old_token)
      assert old_token.revoked_at != nil

      hashed_new_token =
        RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(result.refresh_token)

      new_token = Repo.get_by(Token, token: hashed_new_token)
      assert new_token != nil
      assert new_token.user_id == user.id
      assert new_token.revoked_at == nil
    end

    test "returns error with invalid refresh token" do
      assert {:error, _reason} = RefreshToken.call("invalid_token")
    end

    test "returns error with expired refresh token", %{user: user} do
      expires_at = DateTime.add(DateTime.utc_now(), -1, :day)

      {:ok, token_data} = RecruitmentTest.Guardian.generate_tokens(user)

      hashed_token =
        RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(token_data.refresh_token)

      {:ok, _token} =
        %Token{}
        |> Token.changeset(%{
          token: hashed_token,
          type: "refresh",
          user_id: user.id,
          expires_at: expires_at
        })
        |> Repo.insert()

      assert {:error, "Token has expired"} = RefreshToken.call(token_data.refresh_token)
    end

    test "returns error with revoked refresh token", %{refresh_token: refresh_token} do
      assert {:ok, _result} = RefreshToken.call(refresh_token)

      assert {:error, "Token has been revoked"} = RefreshToken.call(refresh_token)
    end

    test "returns error with non-existent refresh token" do
      {:ok, user} =
        %User{}
        |> User.changeset(%{
          name: "Another User",
          email: "another@example.com",
          password: "Password123",
          role: "user"
        })
        |> Repo.insert()

      {:ok, token_data} = RecruitmentTest.Guardian.generate_tokens(user)

      hashed_token =
        RecruitmentTest.Utils.Validators.Token.HashToken.hash_token(token_data.refresh_token)

      Repo.delete_all(from t in Token, where: t.token == ^hashed_token)

      assert {:error, "Invalid refresh token"} = RefreshToken.call(token_data.refresh_token)
    end

    test "generates different tokens on each refresh", %{refresh_token: refresh_token} do
      {:ok, result1} = RefreshToken.call(refresh_token)
      {:ok, result2} = RefreshToken.call(result1.refresh_token)

      assert result1.access_token != result2.access_token
      assert result1.refresh_token != result2.refresh_token
    end

    test "creates new token record and revokes old one", %{
      user: user,
      refresh_token: refresh_token
    } do
      initial_token_count = Repo.aggregate(from(t in Token, where: t.user_id == ^user.id), :count)

      {:ok, _result} = RefreshToken.call(refresh_token)

      final_token_count = Repo.aggregate(from(t in Token, where: t.user_id == ^user.id), :count)

      assert final_token_count == initial_token_count + 1

      revoked_count =
        Repo.aggregate(
          from(t in Token, where: t.user_id == ^user.id and not is_nil(t.revoked_at)),
          :count
        )

      assert revoked_count == 1
    end

    test "refresh token maintains user context", %{user: user, refresh_token: refresh_token} do
      {:ok, result} = RefreshToken.call(refresh_token)

      {:ok, claims} = RecruitmentTest.Guardian.verify_token(result.access_token)
      {:ok, refreshed_user} = RecruitmentTest.Guardian.resource_from_claims(claims)

      assert refreshed_user.id == user.id
      assert refreshed_user.email == user.email
    end

    test "can chain multiple refresh operations", %{refresh_token: refresh_token} do
      {:ok, result1} = RefreshToken.call(refresh_token)
      {:ok, result2} = RefreshToken.call(result1.refresh_token)
      {:ok, result3} = RefreshToken.call(result2.refresh_token)

      assert result3.access_token
      assert result3.refresh_token

      assert {:error, "Token has been revoked"} = RefreshToken.call(refresh_token)
      assert {:error, "Token has been revoked"} = RefreshToken.call(result1.refresh_token)
      assert {:error, "Token has been revoked"} = RefreshToken.call(result2.refresh_token)
    end
  end
end
