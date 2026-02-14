# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :recruitment_test, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10, email: 10, reports: 10],
  repo: RecruitmentTest.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       {"0 20 * * *", RecruitmentTest.Jobs.DailyReportSummary}
     ]}
  ]

config :recruitment_test,
  ecto_repos: [RecruitmentTest.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :recruitment_test, RecruitmentTest.Repo,
  migration_primary_key: [name: :id, type: :binary_id]

# Configures the endpoint
config :recruitment_test, RecruitmentTestWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: RecruitmentTestWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: RecruitmentTest.PubSub,
  live_view: [signing_salt: "1yyaZW4o"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :recruitment_test, RecruitmentTest.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Guardian configuration
config :recruitment_test, RecruitmentTest.Guardian,
  issuer: "recruitment_test",
  secret_key: "your_secret_key_here_change_in_production"

# Api client configuration
config :recruitment_test, :cnpj_validator, RecruitmentTest.Utils.Validators.Cnpj.CnpjMockValidator

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
