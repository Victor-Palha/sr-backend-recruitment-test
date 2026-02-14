import Config

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: RecruitmentTest.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

# Api client configuration
config :recruitment_test, :cnpj_validator, RecruitmentTest.Utils.Validators.Cnpj.CnpjValidator

config :recruitment_test, RecruitmentTest.Guardian,
  issuer: System.get_env("GUARDIAN_ISSUER") || "recruitment_test",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY")

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
