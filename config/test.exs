import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :recruitment_test, RecruitmentTest.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "recruitment_test_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :recruitment_test, RecruitmentTestWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "WydyJIls9HifJ2G9t1mUo4tzOGE0zbW3VZ1tTDUmZrd1QimHBRR1SQkuSHAorgTn",
  server: false

# In test we don't send emails
config :recruitment_test, RecruitmentTest.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Api client configuration
config :recruitment_test, :cnpj_validator, RecruitmentTest.Utils.Validators.Cnpj.CnpjMockValidator

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
