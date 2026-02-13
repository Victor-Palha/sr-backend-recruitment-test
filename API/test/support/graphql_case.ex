defmodule RecruitmentTestWeb.GraphQLCase do
  @moduledoc """
  This module defines the test case to be used by GraphQL tests.
  """

  use ExUnit.CaseTemplate
  import Phoenix.ConnTest

  @endpoint RecruitmentTestWeb.Endpoint

  using do
    quote do
      import RecruitmentTestWeb.GraphQLCase
      import Phoenix.ConnTest
      alias RecruitmentTest.Repo

      @endpoint RecruitmentTestWeb.Endpoint
    end
  end

  setup tags do
    RecruitmentTest.DataCase.setup_sandbox(tags)
    {:ok, conn: build_conn()}
  end

  @doc """
  Helper to execute a GraphQL query with authentication.
  """
  def query_graphql(conn, query, variables \\ %{}, context \\ %{}) do
    conn
    |> put_graphql_context(context)
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> post("/graphql", %{query: query, variables: variables})
  end

  @doc """
  Helper to create an authenticated context with a user.
  """
  def authenticated_context(user) do
    %{current_user: user, role: user.role}
  end

  @doc """
  Put GraphQL context in the connection for testing.
  """
  def put_graphql_context(conn, context) do
    Absinthe.Plug.put_options(conn, context: context)
  end

  @doc """
  Create a test user with specified role.
  """
  def create_user(attrs \\ %{}) do
    default_attrs = %{
      name: "Test User",
      email: "test#{System.unique_integer()}@example.com",
      password: "Password123",
      role: "user",
      is_active: true
    }

    attrs = Map.merge(default_attrs, attrs)

    %RecruitmentTest.Contexts.Accounts.User{}
    |> RecruitmentTest.Contexts.Accounts.User.changeset(attrs)
    |> RecruitmentTest.Repo.insert!()
  end

  @doc """
  Create a test admin user.
  """
  def create_admin_user(attrs \\ %{}) do
    create_user(Map.merge(attrs, %{role: "admin"}))
  end

  @doc """
  Create a test collaborator.
  """
  def create_collaborator(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Collaborator",
      email: "collaborator#{System.unique_integer()}@example.com",
      cpf: "#{:rand.uniform(89_999_999_999) + 10_000_000_000}",
      is_active: true
    }

    attrs = Map.merge(default_attrs, Enum.into(attrs, %{}))

    %RecruitmentTest.Contexts.Collaborators.Collaborator{}
    |> RecruitmentTest.Contexts.Collaborators.Collaborator.changeset(attrs)
    |> RecruitmentTest.Repo.insert!()
  end

  @doc """
  Create a test enterprise.
  """
  def create_enterprise(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Enterprise",
      commercial_name: "Test Corp",
      cnpj: "#{:rand.uniform(89_999_999) + 10_000_000}000190",
      description: "Test description"
    }

    attrs = Map.merge(default_attrs, Enum.into(attrs, %{}))

    %RecruitmentTest.Contexts.Enterprises.Enterprise{}
    |> RecruitmentTest.Contexts.Enterprises.Enterprise.changeset(attrs)
    |> RecruitmentTest.Repo.insert!()
  end

  @doc """
  Create a test contract.
  """
  def create_contract(attrs \\ %{}) do
    collaborator = attrs[:collaborator] || create_collaborator()
    enterprise = attrs[:enterprise] || create_enterprise()

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    future = DateTime.add(now, 180, :day)

    default_attrs = %{
      collaborator_id: collaborator.id,
      enterprise_id: enterprise.id,
      value: Decimal.new("5000.00"),
      starts_at: now,
      expires_at: future,
      status: "active"
    }

    attrs = Map.merge(default_attrs, Enum.into(attrs, %{}))

    %RecruitmentTest.Contexts.Contracts.Contract{}
    |> RecruitmentTest.Contexts.Contracts.Contract.changeset(attrs)
    |> RecruitmentTest.Repo.insert!()
  end

  @doc """
  Create a test task.
  """
  def create_task(attrs \\ %{}) do
    collaborator = attrs[:collaborator] || create_collaborator()

    default_attrs = %{
      name: "Test Task",
      description: "Test description",
      collaborator_id: collaborator.id,
      status: "pending",
      priority: 1
    }

    attrs = Map.merge(default_attrs, Enum.into(attrs, %{}))

    %RecruitmentTest.Contexts.Tasks.Task{}
    |> RecruitmentTest.Contexts.Tasks.Task.changeset(attrs)
    |> RecruitmentTest.Repo.insert!()
  end

  @doc """
  Create a test report.
  """
  def create_report(attrs \\ %{}) do
    collaborator = attrs[:collaborator] || create_collaborator()
    task = attrs[:task] || create_task(%{collaborator: collaborator})

    default_attrs = %{
      collaborator_id: collaborator.id,
      task_id: task.id,
      task_name: task.name,
      task_description: task.description,
      collaborator_name: collaborator.name,
      completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    attrs = Map.merge(default_attrs, Enum.into(attrs, %{}))

    %RecruitmentTest.Contexts.Reports.Report{}
    |> RecruitmentTest.Contexts.Reports.Report.changeset(attrs)
    |> RecruitmentTest.Repo.insert!()
  end
end
