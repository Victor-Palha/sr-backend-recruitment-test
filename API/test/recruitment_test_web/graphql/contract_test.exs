defmodule RecruitmentTestWeb.Graphql.ContractTest do
  use RecruitmentTestWeb.GraphQLCase
  import Phoenix.ConnTest

  describe "contract query" do
    test "returns contract when authenticated", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator()
      enterprise = create_enterprise()

      contract =
        create_contract(%{collaborator: collaborator, enterprise: enterprise, status: "active"})

      query = """
      query GetContract($id: ID!) {
        contract(id: $id) {
          id
          value
          status
          startsAt
          expiresAt
        }
      }
      """

      conn = query_graphql(conn, query, %{id: contract.id}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["data"]["contract"]["id"] == contract.id
      assert result["data"]["contract"]["status"] == "ACTIVE"
    end

    test "returns error when not authenticated", %{conn: conn} do
      contract = create_contract()

      query = """
      query GetContract($id: ID!) {
        contract(id: $id) {
          id
          value
        }
      }
      """

      conn = query_graphql(conn, query, %{id: contract.id}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end

    test "returns error when contract not found", %{conn: conn} do
      user = create_user()

      query = """
      query GetContract($id: ID!) {
        contract(id: $id) {
          id
          value
        }
      }
      """

      conn = query_graphql(conn, query, %{id: Ecto.UUID.generate()}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Contract not found"
    end
  end

  describe "contracts query" do
    test "returns all contracts when authenticated", %{conn: conn} do
      user = create_user()
      _contract1 = create_contract(%{status: "active"})
      _contract2 = create_contract(%{status: "expired"})

      query = """
      query {
        contracts {
          data {
            id
            status
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn = query_graphql(conn, query, %{}, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["contracts"]["data"]) == 2
      statuses = Enum.map(result["data"]["contracts"]["data"], & &1["status"])
      assert "ACTIVE" in statuses
      assert "EXPIRED" in statuses
    end

    test "returns error when not authenticated", %{conn: conn} do
      query = """
      query {
        contracts {
          data {
            id
            status
          }
        }
      }
      """

      conn = query_graphql(conn, query, %{}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end
  end

  describe "contracts query with pagination" do
    test "returns paginated contracts", %{conn: conn} do
      user = create_user()

      for _i <- 1..12 do
        create_contract(%{status: "active"})
      end

      query = """
      query GetContracts($pagination: PaginationInput) {
        contracts(pagination: $pagination) {
          data {
            id
            status
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            totalCount
          }
        }
      }
      """

      conn =
        query_graphql(
          conn,
          query,
          %{pagination: %{page: 1, pageSize: 5}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["contracts"]["data"]) == 5
      assert result["data"]["contracts"]["pageInfo"]["hasNextPage"] == true
      assert result["data"]["contracts"]["pageInfo"]["totalCount"] == 12
    end
  end

  describe "contracts query with filters" do
    test "filters by status", %{conn: conn} do
      user = create_user()
      _contract1 = create_contract(%{status: "active"})
      _contract2 = create_contract(%{status: "expired"})
      _contract3 = create_contract(%{status: "active"})
      _contract4 = create_contract(%{status: "cancelled"})

      query = """
      query GetContracts($filters: ContractFilters) {
        contracts(filters: $filters) {
          data {
            id
            status
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn =
        query_graphql(conn, query, %{filters: %{status: "ACTIVE"}}, authenticated_context(user))

      result = json_response(conn, 200)

      refute result["errors"], "GraphQL returned errors: #{inspect(result["errors"])}"

      assert length(result["data"]["contracts"]["data"]) == 2
      assert result["data"]["contracts"]["pageInfo"]["totalCount"] == 2

      Enum.each(result["data"]["contracts"]["data"], fn contract ->
        assert contract["status"] == "ACTIVE"
      end)
    end
  end

  describe "createContract mutation" do
    test "creates contract when user is admin", %{conn: conn} do
      admin = create_admin_user()
      collaborator = create_collaborator()
      enterprise = create_enterprise()

      mutation = """
      mutation CreateContract($input: CreateContractInput!) {
        createContract(input: $input) {
          id
          value
          status
        }
      }
      """

      starts_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      expires_at =
        DateTime.utc_now()
        |> DateTime.add(180, :day)
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()

      input = %{
        enterpriseId: enterprise.id,
        collaboratorId: collaborator.id,
        value: "5000.00",
        startsAt: starts_at,
        expiresAt: expires_at,
        status: "ACTIVE"
      }

      conn = query_graphql(conn, mutation, %{input: input}, authenticated_context(admin))
      result = json_response(conn, 200)

      assert result["data"]["createContract"]["status"] == "ACTIVE"
      assert result["data"]["createContract"]["value"] != nil
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator()
      enterprise = create_enterprise()

      mutation = """
      mutation CreateContract($input: CreateContractInput!) {
        createContract(input: $input) {
          id
          value
        }
      }
      """

      starts_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      expires_at =
        DateTime.utc_now()
        |> DateTime.add(180, :day)
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()

      input = %{
        enterpriseId: enterprise.id,
        collaboratorId: collaborator.id,
        value: "5000.00",
        startsAt: starts_at,
        expiresAt: expires_at
      }

      conn = query_graphql(conn, mutation, %{input: input}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end
  end

  describe "updateContract mutation" do
    test "updates contract when user is admin", %{conn: conn} do
      admin = create_admin_user()
      contract = create_contract(%{status: "active"})

      mutation = """
      mutation UpdateContract($id: ID!, $input: UpdateContractInput!) {
        updateContract(id: $id, input: $input) {
          id
          value
          status
        }
      }
      """

      input = %{value: "7000.00", status: "EXPIRED"}

      conn =
        query_graphql(
          conn,
          mutation,
          %{id: contract.id, input: input},
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert result["data"]["updateContract"]["status"] == "EXPIRED"
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()
      contract = create_contract()

      mutation = """
      mutation UpdateContract($id: ID!, $input: UpdateContractInput!) {
        updateContract(id: $id, input: $input) {
          id
          value
        }
      }
      """

      conn =
        query_graphql(
          conn,
          mutation,
          %{id: contract.id, input: %{value: "8000.00"}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end
  end

  describe "deleteContract mutation" do
    test "deletes contract when user is admin", %{conn: conn} do
      admin = create_admin_user()
      contract = create_contract()

      mutation = """
      mutation DeleteContract($id: ID!) {
        deleteContract(id: $id) {
          success
          contract {
            id
          }
        }
      }
      """

      conn = query_graphql(conn, mutation, %{id: contract.id}, authenticated_context(admin))
      result = json_response(conn, 200)

      assert result["data"]["deleteContract"]["success"] == true
      assert result["data"]["deleteContract"]["contract"]["id"] == contract.id
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()
      contract = create_contract()

      mutation = """
      mutation DeleteContract($id: ID!) {
        deleteContract(id: $id) {
          success
        }
      }
      """

      conn = query_graphql(conn, mutation, %{id: contract.id}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end
  end
end
