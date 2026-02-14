defmodule RecruitmentTest.Jobs.DailyReportSummaryTest do
  use RecruitmentTest.DataCase, async: true
  use Oban.Testing, repo: RecruitmentTest.Repo

  import RecruitmentTestWeb.GraphQLCase,
    only: [
      create_admin_user: 0,
      create_admin_user: 1,
      create_user: 1,
      create_collaborator: 0,
      create_collaborator: 1,
      create_task: 1,
      create_report: 1
    ]

  alias RecruitmentTest.Jobs.DailyReportSummary

  describe "perform/1 with no reports" do
    test "returns :ok when no reports exist for today" do
      assert :ok = perform_job(DailyReportSummary, %{})
    end

    test "does not send email when there are no reports" do
      create_admin_user()

      assert :ok = perform_job(DailyReportSummary, %{})

      refute_received {:email, _}
    end
  end

  describe "perform/1 with reports" do
    setup do
      admin = create_admin_user(%{email: "admin@example.com"})
      collaborator = create_collaborator(%{name: "Carlos"})
      task = create_task(%{collaborator: collaborator, name: "Review Invoices"})
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      report =
        create_report(%{
          collaborator: collaborator,
          task: task,
          completed_at: now
        })

      %{admin: admin, collaborator: collaborator, task: task, report: report}
    end

    test "sends summary email to admin users", %{admin: admin} do
      assert :ok = perform_job(DailyReportSummary, %{})

      assert_received {:email, email}
      assert email.to == [{"", admin.email}]
      assert email.from == {"", "onboarding@resend.dev"}
      assert email.subject =~ "Resumo Diário de Relatórios"
    end

    test "email body contains HTML structure" do
      assert :ok = perform_job(DailyReportSummary, %{})

      assert_received {:email, email}
      assert email.html_body =~ "<!DOCTYPE html>"
      assert email.html_body =~ "Recruitment Test"
      assert email.html_body =~ "Resumo Diário de Relatórios"
    end

    test "email body contains the date" do
      assert :ok = perform_job(DailyReportSummary, %{})

      today = Calendar.strftime(Date.utc_today(), "%d/%m/%Y")

      assert_received {:email, email}
      assert email.html_body =~ today
    end

    test "email body contains collaborator stats", %{collaborator: collaborator} do
      assert :ok = perform_job(DailyReportSummary, %{})

      assert_received {:email, email}
      assert email.html_body =~ collaborator.name
      assert email.html_body =~ "Por Colaborador"
    end

    test "email body contains report details", %{task: task, collaborator: collaborator} do
      assert :ok = perform_job(DailyReportSummary, %{})

      assert_received {:email, email}
      assert email.html_body =~ task.name
      assert email.html_body =~ collaborator.name
      assert email.html_body =~ "Detalhes dos Relatórios"
    end

    test "sends email to multiple admins" do
      create_admin_user(%{email: "admin2@example.com"})

      assert :ok = perform_job(DailyReportSummary, %{})

      assert_received {:email, email1}
      assert_received {:email, email2}

      recipients =
        Enum.map([email1, email2], fn email ->
          [{_, addr}] = email.to
          addr
        end)
        |> Enum.sort()

      assert "admin2@example.com" in recipients
      assert "admin@example.com" in recipients
    end

    test "does not send email to regular users" do
      _regular_user = create_user(%{email: "user@example.com", role: "user"})

      assert :ok = perform_job(DailyReportSummary, %{})

      assert_received {:email, email}
      [{_, addr}] = email.to
      assert addr != "user@example.com"
      refute_received {:email, _}
    end
  end

  describe "perform/1 does not include old reports" do
    test "ignores reports from previous days" do
      _admin = create_admin_user()
      collaborator = create_collaborator()
      task = create_task(%{collaborator: collaborator})

      yesterday =
        Date.utc_today()
        |> Date.add(-1)
        |> DateTime.new!(~T[12:00:00])

      create_report(%{collaborator: collaborator, task: task, completed_at: yesterday})

      assert :ok = perform_job(DailyReportSummary, %{})

      refute_received {:email, _}
    end
  end

  describe "perform/1 with many reports" do
    test "shows truncation notice when more than 10 reports exist" do
      _admin = create_admin_user()

      for i <- 1..12 do
        collaborator = create_collaborator(%{name: "Collab #{i}"})
        task = create_task(%{collaborator: collaborator, name: "Task #{i}"})
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        create_report(%{collaborator: collaborator, task: task, completed_at: now})
      end

      assert :ok = perform_job(DailyReportSummary, %{})

      assert_received {:email, email}
      assert email.html_body =~ "Exibindo os 10 mais recentes"
      assert email.html_body =~ "12"
    end
  end

  describe "job configuration" do
    test "job is enqueued with the correct worker and queue" do
      DailyReportSummary.new(%{}) |> Oban.insert!()

      assert_enqueued(worker: DailyReportSummary, queue: :reports)
    end
  end
end
