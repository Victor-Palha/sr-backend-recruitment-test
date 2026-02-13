defmodule RecruitmentTest.Repo do
  use Ecto.Repo,
    otp_app: :recruitment_test,
    adapter: Ecto.Adapters.Postgres
end
