defmodule RecruitmentTest.Guardian do
  use Guardian, otp_app: :recruitment_test

  alias RecruitmentTest.Contexts.Accounts.User
  alias RecruitmentTest.Repo

  def subject_for_token(%User{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Repo.get(User, id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end

  @doc """
  Generates an access token and a refresh token for the given user.
  """
  def generate_tokens(user) do
    with {:ok, access_token, access_claims} <-
           encode_and_sign(user, %{}, token_type: "access", ttl: {1, :hour}),
         {:ok, refresh_token, refresh_claims} <-
           encode_and_sign(user, %{}, token_type: "refresh", ttl: {7, :days}) do
      {:ok,
       %{
         access_token: access_token,
         refresh_token: refresh_token,
         access_claims: access_claims,
         refresh_claims: refresh_claims
       }}
    end
  end

  @doc """
  Verifies and validates a token.
  """
  def verify_token(token) do
    case decode_and_verify(token) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Revokes a token.
  """
  def revoke_token(token, _claims \\ %{}) do
    revoke(token)
  end
end
