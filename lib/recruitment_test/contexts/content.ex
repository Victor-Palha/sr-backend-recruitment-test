defmodule RecruitmentTest.Contexts.Content do
  def data do
    Dataloader.Ecto.new(RecruitmentTest.Repo)
  end
end
