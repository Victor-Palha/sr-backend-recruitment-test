defmodule RecruitmentTest.Jobs.GenerateReportTest do
  use RecruitmentTest.DataCase, async: true
  use Oban.Testing, repo: RecruitmentTest.Repo

  import RecruitmentTestWeb.GraphQLCase,
    only: [create_collaborator: 0, create_task: 1]

  alias RecruitmentTest.Jobs.GenerateReport
  alias RecruitmentTest.Contexts.Reports.Report

  describe "perform/1" do
    test "creates a report for a valid task" do
      collaborator = create_collaborator()
      task = create_task(%{collaborator: collaborator})

      assert {:ok, %Report{} = report} = perform_job(GenerateReport, %{"id" => task.id})

      assert report.task_id == task.id
      assert report.task_name == task.name
      assert report.task_description == task.description
      assert report.collaborator_id == collaborator.id
      assert report.collaborator_name == collaborator.name
      assert report.completed_at != nil
    end

    test "report is persisted in the database" do
      collaborator = create_collaborator()
      task = create_task(%{collaborator: collaborator})

      perform_job(GenerateReport, %{"id" => task.id})

      assert Repo.get_by(Report, task_id: task.id) != nil
    end

    test "returns :ok when task is not found" do
      fake_id = Ecto.UUID.generate()

      assert :ok = perform_job(GenerateReport, %{"id" => fake_id})
      assert Repo.all(Report) == []
    end

    test "does not create a report when task is not found" do
      fake_id = Ecto.UUID.generate()

      assert :ok = perform_job(GenerateReport, %{"id" => fake_id})
      assert Repo.all(Report) == []
    end

    test "completed_at is set to current time (truncated to seconds)" do
      collaborator = create_collaborator()
      task = create_task(%{collaborator: collaborator})

      before = DateTime.utc_now() |> DateTime.truncate(:second)
      {:ok, report} = perform_job(GenerateReport, %{"id" => task.id})
      after_time = DateTime.utc_now() |> DateTime.truncate(:second)

      assert DateTime.compare(report.completed_at, before) in [:eq, :gt]
      assert DateTime.compare(report.completed_at, after_time) in [:eq, :lt]
    end

    test "job is enqueued with the correct worker and queue" do
      GenerateReport.new(%{"id" => Ecto.UUID.generate()}) |> Oban.insert!()

      assert_enqueued(worker: GenerateReport, queue: :reports)
    end
  end
end
