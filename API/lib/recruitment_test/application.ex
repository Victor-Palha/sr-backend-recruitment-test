defmodule RecruitmentTest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RecruitmentTestWeb.Telemetry,
      RecruitmentTest.Repo,
      {DNSCluster, query: Application.get_env(:recruitment_test, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RecruitmentTest.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: RecruitmentTest.Finch},
      # Start a worker by calling: RecruitmentTest.Worker.start_link(arg)
      # {RecruitmentTest.Worker, arg},
      # Start to serve requests, typically the last entry
      RecruitmentTestWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RecruitmentTest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RecruitmentTestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
