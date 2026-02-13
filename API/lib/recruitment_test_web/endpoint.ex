defmodule RecruitmentTestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :recruitment_test

  @session_options [
    store: :cookie,
    key: "_recruitment_key",
    signing_salt: "bQWOClHX",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, longpoll: [connect_info: [session: @session_options]]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :recruitment_test
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Corsica,
    origins: [
      "http://localhost",
      ~r{^http?://(.*\.)?localhost\:(.*)$},
      ~r{^https?://(.*\.)?localhost\:(.*)$}
    ],
    allow_credentials: true,
    allow_headers: :all,
    expose_headers: ["Set-Cookie"]

  plug Plug.Session, @session_options
  plug RecruitmentTestWeb.Router
end
