defmodule RecruitmentTest.Utils.Validators.Token.HashToken do
  @moduledoc """
  Utility module for hashing tokens using SHA256.
  Unlike passwords, tokens should use deterministic hashing without salt.
  """

  def hash_token(token) do
    :crypto.hash(:sha256, token)
    |> Base.encode64()
  end

  def verify_token(token, token_hash) do
    hash_token(token) == token_hash
  end
end
