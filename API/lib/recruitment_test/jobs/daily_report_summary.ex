defmodule RecruitmentTest.Jobs.DailyReportSummary do
  @moduledoc """
  This job is responsible for generating a daily summary report of all tasks completed on the current day. It retrieves all reports generated on the current day, compiles a summary of the total number of reports, the number of reports per collaborator, and details of each report. The summary is then sended to all administrators via email. This job is scheduled to run once every day at a specific time using Oban's scheduling capabilities.
  """
  import Swoosh.Email

  use Oban.Worker,
    queue: :reports,
    max_attempts: 3

  require Logger

  import Ecto.Query
  alias RecruitmentTest.Repo
  alias RecruitmentTest.Contexts.Reports.Report
  alias RecruitmentTest.Contexts.Accounts.User

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Logger.metadata(oban_job_id: job.id, oban_worker: "DailyReportSummary", oban_queue: "reports")
    Logger.info("Starting daily report summary generation", job: "daily_report_summary")

    today = Date.utc_today()
    reports = fetch_today_reports(today)

    case reports do
      [] ->
        Logger.info("No reports generated today",
          job: "daily_report_summary",
          date: to_string(today)
        )

        :ok

      reports ->
        Logger.info("Sending daily report summary",
          job: "daily_report_summary",
          date: to_string(today),
          report_count: length(reports)
        )

        send_daily_summary(reports, today)
        :ok
    end
  end

  defp fetch_today_reports(date) do
    start_of_day = DateTime.new!(date, ~T[00:00:00])
    end_of_day = DateTime.new!(date, ~T[23:59:59])

    Report
    |> where([r], r.completed_at >= ^start_of_day and r.completed_at <= ^end_of_day)
    |> order_by([r], desc: r.completed_at)
    |> Repo.all()
  end

  defp send_daily_summary(reports, date) do
    html = build_html_email(reports, date)
    send_email_to_admins(html)
  end

  defp build_html_email(reports, date) do
    total = length(reports)

    by_collaborator =
      reports
      |> Enum.group_by(& &1.collaborator_name)
      |> Enum.map(fn {name, collab_reports} -> {name, length(collab_reports)} end)
      |> Enum.sort_by(fn {_name, count} -> count end, :desc)

    formatted_date = Calendar.strftime(date, "%d/%m/%Y")

    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      </head>
      <body style="margin:0;padding:0;background-color:#f4f6f9;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;padding:40px 0;">
          <tr>
            <td align="center">
              <table role="presentation" width="640" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
                <!-- Header -->
                <tr>
                  <td style="background:linear-gradient(135deg,#1a73e8,#0d47a1);padding:36px 32px;text-align:center;">
                    <h1 style="margin:0;color:#ffffff;font-size:26px;font-weight:700;letter-spacing:-0.5px;">
                      Recruitment Test - Relatório Diário
                    </h1>
                    <p style="margin:10px 0 0;color:rgba(255,255,255,0.9);font-size:15px;font-weight:400;">
                      Resumo Diário de Relatórios
                    </p>
                  </td>
                </tr>
                <!-- Summary Stats -->
                <tr>
                  <td style="padding:32px 32px 0;">
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td width="50%" style="padding-right:8px;">
                          <div style="background-color:#f0f7ff;border-radius:10px;padding:20px;text-align:center;">
                            <p style="margin:0;color:#6b7280;font-size:13px;text-transform:uppercase;letter-spacing:0.5px;">Data</p>
                            <p style="margin:6px 0 0;color:#1a1a2e;font-size:20px;font-weight:700;">#{formatted_date}</p>
                          </div>
                        </td>
                        <td width="50%" style="padding-left:8px;">
                          <div style="background-color:#f0fdf4;border-radius:10px;padding:20px;text-align:center;">
                            <p style="margin:0;color:#6b7280;font-size:13px;text-transform:uppercase;letter-spacing:0.5px;">Total de Relatórios</p>
                            <p style="margin:6px 0 0;color:#166534;font-size:20px;font-weight:700;">#{total}</p>
                          </div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <!-- By Collaborator -->
                <tr>
                  <td style="padding:28px 32px 0;">
                    <h2 style="margin:0 0 16px;color:#1a1a2e;font-size:18px;font-weight:600;border-bottom:2px solid #e5e7eb;padding-bottom:8px;">
                      Por Colaborador
                    </h2>
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;">
                      <tr style="background-color:#f9fafb;">
                        <td style="padding:10px 14px;font-size:12px;font-weight:600;color:#6b7280;text-transform:uppercase;letter-spacing:0.5px;border-bottom:1px solid #e5e7eb;">Colaborador</td>
                        <td style="padding:10px 14px;font-size:12px;font-weight:600;color:#6b7280;text-transform:uppercase;letter-spacing:0.5px;text-align:center;border-bottom:1px solid #e5e7eb;">Relatórios</td>
                      </tr>
    #{build_collaborator_rows(by_collaborator)}
                    </table>
                  </td>
                </tr>
                <!-- Report Details -->
                <tr>
                  <td style="padding:28px 32px 0;">
                    <h2 style="margin:0 0 16px;color:#1a1a2e;font-size:18px;font-weight:600;border-bottom:2px solid #e5e7eb;padding-bottom:8px;">
                      Detalhes dos Relatórios
                    </h2>
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;">
                      <tr style="background-color:#f9fafb;">
                        <td style="padding:10px 14px;font-size:12px;font-weight:600;color:#6b7280;text-transform:uppercase;letter-spacing:0.5px;border-bottom:1px solid #e5e7eb;">Tarefa</td>
                        <td style="padding:10px 14px;font-size:12px;font-weight:600;color:#6b7280;text-transform:uppercase;letter-spacing:0.5px;border-bottom:1px solid #e5e7eb;">Colaborador</td>
                        <td style="padding:10px 14px;font-size:12px;font-weight:600;color:#6b7280;text-transform:uppercase;letter-spacing:0.5px;text-align:center;border-bottom:1px solid #e5e7eb;">Concluído em</td>
                      </tr>
    #{build_report_rows(reports)}
                    </table>
    #{if length(reports) > 10, do: "<p style=\"margin:12px 0 0;color:#9ca3af;font-size:13px;text-align:center;\">Exibindo os 10 mais recentes de #{total} relatórios</p>", else: ""}
                  </td>
                </tr>
                <!-- Footer -->
                <tr>
                  <td style="padding:28px 32px;margin-top:16px;">
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td style="background-color:#f9fafb;border-radius:8px;padding:20px 24px;border-top:1px solid #e5e7eb;text-align:center;">
                          <p style="margin:0;color:#9ca3af;font-size:13px;">
                            Este é um email automático gerado pela plataforma <strong>Recruitment Test</strong>.
                          </p>
                          <p style="margin:8px 0 0;color:#9ca3af;font-size:12px;">
                            #{formatted_date} &bull; Relatório diário
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end

  defp build_collaborator_rows(stats) do
    stats
    |> Enum.with_index()
    |> Enum.map(fn {{name, count}, index} ->
      bg = if rem(index, 2) == 0, do: "#ffffff", else: "#f9fafb"

      """
                      <tr style="background-color:#{bg};">
                        <td style="padding:12px 14px;font-size:14px;color:#1a1a2e;border-bottom:1px solid #f3f4f6;">#{name}</td>
                        <td style="padding:12px 14px;font-size:14px;color:#1a1a2e;text-align:center;border-bottom:1px solid #f3f4f6;">
                          <span style="background-color:#e0f2fe;color:#0369a1;padding:3px 12px;border-radius:12px;font-weight:600;font-size:13px;">#{count}</span>
                        </td>
                      </tr>
      """
    end)
    |> Enum.join()
  end

  defp build_report_rows(reports) do
    reports
    |> Enum.take(10)
    |> Enum.with_index()
    |> Enum.map(fn {report, index} ->
      bg = if rem(index, 2) == 0, do: "#ffffff", else: "#f9fafb"
      completed = format_datetime(report.completed_at)

      """
                      <tr style="background-color:#{bg};">
                        <td style="padding:12px 14px;font-size:14px;color:#1a1a2e;border-bottom:1px solid #f3f4f6;">#{report.task_name}</td>
                        <td style="padding:12px 14px;font-size:14px;color:#4b5563;border-bottom:1px solid #f3f4f6;">#{report.collaborator_name}</td>
                        <td style="padding:12px 14px;font-size:13px;color:#6b7280;text-align:center;border-bottom:1px solid #f3f4f6;">#{completed}</td>
                      </tr>
      """
    end)
    |> Enum.join()
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y %H:%M")
  end

  defp find_all_admins do
    User
    |> where([u], u.role == "admin")
    |> Repo.all()
  end

  def send_email_to_admins(report) do
    admins = find_all_admins()

    Enum.each(admins, fn admin ->
      new()
      |> to(admin.email)
      |> Swoosh.Email.from("onboarding@resend.dev")
      |> subject(
        "Resumo Diário de Relatórios - #{Calendar.strftime(Date.utc_today(), "%d/%m/%Y")}"
      )
      |> html_body(report)
      |> RecruitmentTest.Mailer.deliver()
    end)
  end
end
