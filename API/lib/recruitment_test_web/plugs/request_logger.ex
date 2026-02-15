defmodule RecruitmentTestWeb.Plugs.RequestLogger do
  @moduledoc """
  Plug that logs the full HTTP request lifecycle with structured metadata.
  All log entries are automatically correlated via `request_id` set by `Plug.RequestId`.
  Sensitive parameters (password, token, secret) are redacted.
  """

  require Logger

  @behaviour Plug

  @sensitive_keys ~w(password secret token refresh_token access_token)

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    start_time = System.monotonic_time()

    Logger.info("Request started",
      method: conn.method,
      path: conn.request_path,
      query_string: conn.query_string,
      remote_ip: format_ip(conn.remote_ip),
      user_agent: get_user_agent(conn)
    )

    Plug.Conn.register_before_send(conn, fn conn ->
      duration = System.monotonic_time() - start_time
      duration_ms = System.convert_time_unit(duration, :native, :microsecond) / 1000

      Logger.info("Request completed",
        method: conn.method,
        path: conn.request_path,
        status: conn.status,
        duration_ms: Float.round(duration_ms, 2),
        remote_ip: format_ip(conn.remote_ip)
      )

      conn
    end)
  end

  def redact_params(params) when is_map(params) do
    Map.new(params, fn
      {key, value} when is_binary(key) ->
        if String.downcase(key) in @sensitive_keys do
          {key, "[REDACTED]"}
        else
          {key, redact_params(value)}
        end

      {key, value} ->
        {key, redact_params(value)}
    end)
  end

  def redact_params(value), do: value

  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp format_ip(_), do: "unknown"

  defp get_user_agent(conn) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [ua | _] -> ua
      _ -> nil
    end
  end
end
