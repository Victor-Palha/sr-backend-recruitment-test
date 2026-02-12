defmodule RecruitmentTest.Contexts.Enterprises.Services.Create do
  @moduledoc """
  Service module responsible for creating a new enterprise.
  """
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Repo

  def call(attrs) do
    %Enterprise{}
    |> Enterprise.changeset(attrs)
    |> Repo.insert()
  end
end
