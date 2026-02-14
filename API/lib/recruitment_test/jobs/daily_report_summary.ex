defmodule RecruitmentTest.Jobs.DailyReportSummary do
  @moduledoc """
  This job is responsible for generating a daily summary report of all tasks completed on the current day. It retrieves all reports generated on the current day, compiles a summary of the total number of reports, the number of reports per collaborator, and details of each report. The summary is then printed to the console, but in a real application, this could be sent via email or another notification system.
  """

  use Oban.Worker,
    queue: :reports,
    max_attempts: 3

  import Ecto.Query
  alias RecruitmentTest.Repo
  alias RecruitmentTest.Contexts.Reports.Report

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    today = Date.utc_today()
    reports = fetch_today_reports(today)

    case reports do
      [] ->
        IO.puts("No reports generated today (#{today})")
        :ok

      reports ->
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
    summary = build_summary(reports, date)

    IO.puts("=" <> String.duplicate("=", 50))
    IO.puts("DAILY SUMMARY REPORT - #{date}")
    IO.puts("=" <> String.duplicate("=", 50))
    IO.puts(summary)
    IO.puts("=" <> String.duplicate("=", 50))
  end

  defp build_summary(reports, date) do
    total = length(reports)

    by_collaborator =
      reports
      |> Enum.group_by(& &1.collaborator_name)
      |> Enum.map(fn {name, reports} -> {name, length(reports)} end)
      |> Enum.sort_by(fn {_name, count} -> count end, :desc)

    """
    Date: #{date}
    Total Reports: #{total}

    By Collaborator:
    #{format_collaborator_stats(by_collaborator)}

    Details:
    #{format_report_details(reports)}
    """
  end

  defp format_collaborator_stats(stats) do
    stats
    |> Enum.map(fn {name, count} -> "  - #{name}: #{count} report(s)" end)
    |> Enum.join("\n")
  end

  defp format_report_details(reports) do
    reports
    |> Enum.take(10)
    |> Enum.map(fn report ->
      "  - #{report.task_name} (#{report.collaborator_name}) - #{report.completed_at}"
    end)
    |> Enum.join("\n")
  end
end
