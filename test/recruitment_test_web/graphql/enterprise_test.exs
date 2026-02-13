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
          id
          name
          commercialName
        }
      }
      """

      conn = query_graphql(conn, query, %{}, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["enterprises"]) == 2
      names = Enum.map(result["data"]["enterprises"], & &1["name"])
      assert "Enterprise One" in names
      assert "Enterprise Two" in names
    end

    test "returns error when not authenticated", %{conn: conn} do
      query = """
      query {
        enterprises {
          id
          name
        }
      }
      """

      conn = query_graphql(conn, query, %{}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
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
        name: "New Enterprise Ltd",
        commercialName: "New Enterprise",
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
        name: "New Enterprise Ltd",
        commercialName: "New Enterprise",
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
        name: "New Enterprise Ltd",
        commercialName: "New Enterprise",
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
