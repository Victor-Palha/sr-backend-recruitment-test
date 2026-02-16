import Config

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger,
  level: :info

# Api client configuration
config :recruitment_test, :cnpj_validator, RecruitmentTest.Utils.Validators.Cnpj.CnpjValidator

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
