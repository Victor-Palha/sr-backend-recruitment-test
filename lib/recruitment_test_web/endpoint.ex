defmodule RecruitmentTestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :recruitment_test

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :recruitment_test
  end

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

  plug RecruitmentTestWeb.Router
end
