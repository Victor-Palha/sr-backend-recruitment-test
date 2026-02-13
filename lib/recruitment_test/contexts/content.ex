defmodule RecruitmentTest.Contexts.Content do
  def data do
    Dataloader.Ecto.new(Graphs.Repo)
  end
end
