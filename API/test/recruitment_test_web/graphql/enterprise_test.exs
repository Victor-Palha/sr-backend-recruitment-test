defmodule RecruitmentTestWeb.Graphql.EnterpriseTest do
  use RecruitmentTestWeb.GraphQLCase
  import Phoenix.ConnTest

  describe "enterprise query" do
    test "returns enterprise when authenticated", %{conn: conn} do
      user = create_user()
      enterprise = create_enterprise(%{name: "Tech Solutions", commercial_name: "Tech Corp"})

      query = """
      query GetEnterprise($id: ID!) {
        enterprise(id: $id) {
          id
          name
          commercialName
          cnpj
          description
        }
      }
      """

      conn = query_graphql(conn, query, %{id: enterprise.id}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["data"]["enterprise"]["id"] == enterprise.id
      assert result["data"]["enterprise"]["name"] == "Tech Solutions"
      assert result["data"]["enterprise"]["commercialName"] == "Tech Corp"
    end

    test "returns error when not authenticated", %{conn: conn} do
      enterprise = create_enterprise()

      query = """
      query GetEnterprise($id: ID!) {
        enterprise(id: $id) {
          id
          name
        }
      }
      """

      conn = query_graphql(conn, query, %{id: enterprise.id}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end

    test "returns error when enterprise not found", %{conn: conn} do
      user = create_user()

      query = """
      query GetEnterprise($id: ID!) {
        enterprise(id: $id) {
          id
          name
        }
      }
      """

      conn = query_graphql(conn, query, %{id: Ecto.UUID.generate()}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Enterprise not found"
    end
  end

  describe "enterprises query" do
    test "returns all enterprises when authenticated", %{conn: conn} do
      user = create_user()
      _enterprise1 = create_enterprise(%{name: "Enterprise One"})
      _enterprise2 = create_enterprise(%{name: "Enterprise Two"})

      query = """
      query {
        enterprises {
          data {
            id
            name
            commercialName
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn = query_graphql(conn, query, %{}, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["enterprises"]["data"]) == 2
      names = Enum.map(result["data"]["enterprises"]["data"], & &1["name"])
      assert "Enterprise One" in names
      assert "Enterprise Two" in names
    end

    test "returns error when not authenticated", %{conn: conn} do
      query = """
      query {
        enterprises {
          data {
            id
            name
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

  describe "enterprises query with pagination" do
    test "returns paginated enterprises", %{conn: conn} do
      user = create_user()

      for i <- 1..12 do
        create_enterprise(%{
          name: "Enterprise #{i}",
          commercial_name: "Corp #{i}",
          cnpj: "1234567800#{String.pad_leading("#{i}", 4, "0")}"
        })
      end

      query = """
      query GetEnterprises($pagination: PaginationInput) {
        enterprises(pagination: $pagination) {
          data {
            id
            name
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

      assert length(result["data"]["enterprises"]["data"]) == 5
      assert result["data"]["enterprises"]["pageInfo"]["hasNextPage"] == true
      assert result["data"]["enterprises"]["pageInfo"]["hasPreviousPage"] == false
      assert result["data"]["enterprises"]["pageInfo"]["totalCount"] == 12
    end
  end

  describe "enterprises query with filters" do
    test "filters by name", %{conn: conn} do
      user = create_user()
      _enterprise1 = create_enterprise(%{name: "Tech Solutions", commercial_name: "Tech Corp"})
      _enterprise2 = create_enterprise(%{name: "Business Corp", commercial_name: "Business Inc"})
      _enterprise3 = create_enterprise(%{name: "Tech Industries", commercial_name: "Tech Ind"})

      query = """
      query GetEnterprises($filters: EnterpriseFilters) {
        enterprises(filters: $filters) {
          data {
            id
            name
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn = query_graphql(conn, query, %{filters: %{name: "Tech"}}, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["enterprises"]["data"]) == 2
      assert result["data"]["enterprises"]["pageInfo"]["totalCount"] == 2
      names = Enum.map(result["data"]["enterprises"]["data"], & &1["name"])
      assert "Tech Solutions" in names
      assert "Tech Industries" in names
    end

    test "filters by cnpj", %{conn: conn} do
      user = create_user()

      _enterprise1 =
        create_enterprise(%{name: "Company A", commercial_name: "A Inc", cnpj: "12345678000190"})

      _enterprise2 =
        create_enterprise(%{name: "Company B", commercial_name: "B Inc", cnpj: "98765432000100"})

      _enterprise3 =
        create_enterprise(%{name: "Company C", commercial_name: "C Inc", cnpj: "12345678000200"})

      query = """
      query GetEnterprises($filters: EnterpriseFilters) {
        enterprises(filters: $filters) {
          data {
            id
            name
            cnpj
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn =
        query_graphql(conn, query, %{filters: %{cnpj: "123456"}}, authenticated_context(user))

      result = json_response(conn, 200)

      assert length(result["data"]["enterprises"]["data"]) == 2
      assert result["data"]["enterprises"]["pageInfo"]["totalCount"] == 2
    end
  end

  describe "createEnterprise mutation" do
    test "creates enterprise when user is admin", %{conn: conn} do
      admin = create_admin_user()

      mutation = """
      mutation CreateEnterprise($input: CreateEnterpriseInput!) {
        createEnterprise(input: $input) {
          id
          name
          commercialName
          cnpj
          description
        }
      }
      """

      input = %{
        cnpj: "12345678000190",
        description: "A new enterprise"
      }

      conn = query_graphql(conn, mutation, %{input: input}, authenticated_context(admin))
      result = json_response(conn, 200)

      assert result["data"]["createEnterprise"]["name"] == "Teste Corp"
      assert result["data"]["createEnterprise"]["commercialName"] == "EMPRESA TESTE LTDA"
      assert result["data"]["createEnterprise"]["description"] == "A new enterprise"
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()

      mutation = """
      mutation CreateEnterprise($input: CreateEnterpriseInput!) {
        createEnterprise(input: $input) {
          id
          name
        }
      }
      """

      input = %{
        cnpj: "12345678000190"
      }

      conn = query_graphql(conn, mutation, %{input: input}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end

    test "returns error when not authenticated", %{conn: conn} do
      mutation = """
      mutation CreateEnterprise($input: CreateEnterpriseInput!) {
        createEnterprise(input: $input) {
          id
          name
        }
      }
      """

      input = %{
        cnpj: "12345678000190"
      }

      conn = query_graphql(conn, mutation, %{input: input}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end
  end

  describe "updateEnterprise mutation" do
    test "updates enterprise when user is admin", %{conn: conn} do
      admin = create_admin_user()
      enterprise = create_enterprise(%{name: "Old Name"})

      mutation = """
      mutation UpdateEnterprise($id: ID!, $input: UpdateEnterpriseInput!) {
        updateEnterprise(id: $id, input: $input) {
          id
          name
          commercialName
          description
        }
      }
      """

      input = %{
        name: "Updated Name",
        commercialName: "Updated Corp",
        description: "Updated description"
      }

      conn =
        query_graphql(
          conn,
          mutation,
          %{id: enterprise.id, input: input},
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert result["data"]["updateEnterprise"]["name"] == "Updated Name"
      assert result["data"]["updateEnterprise"]["commercialName"] == "Updated Corp"
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()
      enterprise = create_enterprise()

      mutation = """
      mutation UpdateEnterprise($id: ID!, $input: UpdateEnterpriseInput!) {
        updateEnterprise(id: $id, input: $input) {
          id
          name
        }
      }
      """

      conn =
        query_graphql(
          conn,
          mutation,
          %{id: enterprise.id, input: %{name: "New"}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end
  end

  describe "deleteEnterprise mutation" do
    test "deletes enterprise when user is admin", %{conn: conn} do
      admin = create_admin_user()
      enterprise = create_enterprise()

      mutation = """
      mutation DeleteEnterprise($id: ID!) {
        deleteEnterprise(id: $id) {
          success
          enterprise {
            id
            name
          }
        }
      }
      """

      conn = query_graphql(conn, mutation, %{id: enterprise.id}, authenticated_context(admin))
      result = json_response(conn, 200)

      assert result["data"]["deleteEnterprise"]["success"] == true
      assert result["data"]["deleteEnterprise"]["enterprise"]["id"] == enterprise.id
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()
      enterprise = create_enterprise()

      mutation = """
      mutation DeleteEnterprise($id: ID!) {
        deleteEnterprise(id: $id) {
          success
        }
      }
      """

      conn = query_graphql(conn, mutation, %{id: enterprise.id}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end
  end
end
