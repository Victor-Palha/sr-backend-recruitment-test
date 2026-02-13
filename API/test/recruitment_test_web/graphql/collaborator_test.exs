defmodule RecruitmentTestWeb.Graphql.CollaboratorTest do
  use RecruitmentTestWeb.GraphQLCase
  import Phoenix.ConnTest

  describe "collaborator query" do
    test "returns collaborator when authenticated", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator(%{name: "John Doe", email: "john@example.com"})

      query = """
      query GetCollaborator($id: ID!) {
        collaborator(id: $id) {
          id
          name
          email
          cpf
          isActive
        }
      }
      """

      conn = query_graphql(conn, query, %{id: collaborator.id}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["data"]["collaborator"]["id"] == collaborator.id
      assert result["data"]["collaborator"]["name"] == "John Doe"
      assert result["data"]["collaborator"]["email"] == "john@example.com"
    end

    test "returns error when not authenticated", %{conn: conn} do
      collaborator = create_collaborator()

      query = """
      query GetCollaborator($id: ID!) {
        collaborator(id: $id) {
          id
          name
        }
      }
      """

      conn = query_graphql(conn, query, %{id: collaborator.id}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end

    test "returns error when collaborator not found", %{conn: conn} do
      user = create_user()

      query = """
      query GetCollaborator($id: ID!) {
        collaborator(id: $id) {
          id
          name
        }
      }
      """

      conn = query_graphql(conn, query, %{id: Ecto.UUID.generate()}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Collaborator not found"
    end
  end

  describe "collaborators query" do
    test "returns all collaborators when authenticated", %{conn: conn} do
      user = create_user()
      _collaborator1 = create_collaborator(%{name: "Alice"})
      _collaborator2 = create_collaborator(%{name: "Bob"})

      query = """
      query {
        collaborators {
          data {
            id
            name
            email
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            totalCount
          }
        }
      }
      """

      conn = query_graphql(conn, query, %{}, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]["data"]) == 2
      names = Enum.map(result["data"]["collaborators"]["data"], & &1["name"])
      assert "Alice" in names
      assert "Bob" in names
      assert result["data"]["collaborators"]["pageInfo"]["totalCount"] == 2
    end

    test "returns error when not authenticated", %{conn: conn} do
      query = """
      query {
        collaborators {
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

  describe "collaborators query with pagination" do
    test "returns paginated collaborators", %{conn: conn} do
      user = create_user()

      # Create 15 collaborators
      for i <- 1..15 do
        create_collaborator(%{name: "Collaborator #{i}", email: "user#{i}@example.com"})
      end

      query = """
      query GetCollaborators($pagination: PaginationInput) {
        collaborators(pagination: $pagination) {
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

      # Test first page
      conn =
        query_graphql(
          conn,
          query,
          %{pagination: %{page: 1, pageSize: 5}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]["data"]) == 5
      assert result["data"]["collaborators"]["pageInfo"]["hasNextPage"] == true
      assert result["data"]["collaborators"]["pageInfo"]["hasPreviousPage"] == false
      assert result["data"]["collaborators"]["pageInfo"]["totalCount"] == 15
    end

    test "returns second page correctly", %{conn: conn} do
      user = create_user()

      for i <- 1..15 do
        create_collaborator(%{name: "Collaborator #{i}", email: "user#{i}@example.com"})
      end

      query = """
      query GetCollaborators($pagination: PaginationInput) {
        collaborators(pagination: $pagination) {
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
          %{pagination: %{page: 2, pageSize: 5}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]["data"]) == 5
      assert result["data"]["collaborators"]["pageInfo"]["hasNextPage"] == true
      assert result["data"]["collaborators"]["pageInfo"]["hasPreviousPage"] == true
      assert result["data"]["collaborators"]["pageInfo"]["totalCount"] == 15
    end

    test "returns last page correctly", %{conn: conn} do
      user = create_user()

      for i <- 1..15 do
        create_collaborator(%{name: "Collaborator #{i}", email: "user#{i}@example.com"})
      end

      query = """
      query GetCollaborators($pagination: PaginationInput) {
        collaborators(pagination: $pagination) {
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
          %{pagination: %{page: 3, pageSize: 5}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]["data"]) == 5
      assert result["data"]["collaborators"]["pageInfo"]["hasNextPage"] == false
      assert result["data"]["collaborators"]["pageInfo"]["hasPreviousPage"] == true
      assert result["data"]["collaborators"]["pageInfo"]["totalCount"] == 15
    end
  end

  describe "collaborators query with filters" do
    test "filters by name", %{conn: conn} do
      user = create_user()
      _collaborator1 = create_collaborator(%{name: "Alice Smith", email: "alice@example.com"})
      _collaborator2 = create_collaborator(%{name: "Bob Jones", email: "bob@example.com"})
      _collaborator3 = create_collaborator(%{name: "Alice Johnson", email: "alice.j@example.com"})

      query = """
      query GetCollaborators($filters: CollaboratorFilters) {
        collaborators(filters: $filters) {
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

      conn = query_graphql(conn, query, %{filters: %{name: "Alice"}}, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]["data"]) == 2
      assert result["data"]["collaborators"]["pageInfo"]["totalCount"] == 2
      names = Enum.map(result["data"]["collaborators"]["data"], & &1["name"])
      assert "Alice Smith" in names
      assert "Alice Johnson" in names
    end

    test "filters by email", %{conn: conn} do
      user = create_user()
      _collaborator1 = create_collaborator(%{name: "Alice", email: "alice@company.com"})
      _collaborator2 = create_collaborator(%{name: "Bob", email: "bob@othercompany.com"})
      _collaborator3 = create_collaborator(%{name: "Charlie", email: "charlie@company.com"})

      query = """
      query GetCollaborators($filters: CollaboratorFilters) {
        collaborators(filters: $filters) {
          data {
            id
            name
            email
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn =
        query_graphql(
          conn,
          query,
          %{filters: %{email: "@company.com"}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]["data"]) == 2
      assert result["data"]["collaborators"]["pageInfo"]["totalCount"] == 2
      names = Enum.map(result["data"]["collaborators"]["data"], & &1["name"])
      assert "Alice" in names
      assert "Charlie" in names
    end

    test "filters by isActive", %{conn: conn} do
      user = create_user()
      _collaborator1 = create_collaborator(%{name: "Active User", is_active: true})
      _collaborator2 = create_collaborator(%{name: "Inactive User", is_active: false})
      _collaborator3 = create_collaborator(%{name: "Another Active", is_active: true})

      query = """
      query GetCollaborators($filters: CollaboratorFilters) {
        collaborators(filters: $filters) {
          data {
            id
            name
            isActive
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn =
        query_graphql(conn, query, %{filters: %{isActive: false}}, authenticated_context(user))

      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]["data"]) == 1
      assert result["data"]["collaborators"]["pageInfo"]["totalCount"] == 1
      assert hd(result["data"]["collaborators"]["data"])["name"] == "Inactive User"
      assert hd(result["data"]["collaborators"]["data"])["isActive"] == false
    end

    test "combines multiple filters", %{conn: conn} do
      user = create_user()

      _collaborator1 =
        create_collaborator(%{
          name: "Alice Smith",
          email: "alice.smith@company.com",
          is_active: true
        })

      _collaborator2 =
        create_collaborator(%{
          name: "Alice Jones",
          email: "alice.jones@company.com",
          is_active: false
        })

      _collaborator3 =
        create_collaborator(%{name: "Bob Smith", email: "bob@company.com", is_active: true})

      query = """
      query GetCollaborators($filters: CollaboratorFilters) {
        collaborators(filters: $filters) {
          data {
            id
            name
            email
            isActive
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn =
        query_graphql(
          conn,
          query,
          %{filters: %{name: "Alice", isActive: true}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]["data"]) == 1
      assert result["data"]["collaborators"]["pageInfo"]["totalCount"] == 1
      assert hd(result["data"]["collaborators"]["data"])["name"] == "Alice Smith"
    end
  end

  describe "collaborators query with pagination and filters combined" do
    test "paginates filtered results", %{conn: conn} do
      user = create_user()

      # Create 10 active and 5 inactive collaborators
      for i <- 1..10 do
        create_collaborator(%{
          name: "Active #{i}",
          email: "active#{i}@example.com",
          is_active: true
        })
      end

      for i <- 1..5 do
        create_collaborator(%{
          name: "Inactive #{i}",
          email: "inactive#{i}@example.com",
          is_active: false
        })
      end

      query = """
      query GetCollaborators($pagination: PaginationInput, $filters: CollaboratorFilters) {
        collaborators(pagination: $pagination, filters: $filters) {
          data {
            id
            name
            isActive
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            totalCount
          }
        }
      }
      """

      variables = %{
        pagination: %{page: 1, pageSize: 5},
        filters: %{isActive: true}
      }

      conn = query_graphql(conn, query, variables, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]["data"]) == 5
      assert result["data"]["collaborators"]["pageInfo"]["hasNextPage"] == true
      assert result["data"]["collaborators"]["pageInfo"]["hasPreviousPage"] == false
      assert result["data"]["collaborators"]["pageInfo"]["totalCount"] == 10

      # Verify all returned are active
      Enum.each(result["data"]["collaborators"]["data"], fn collab ->
        assert collab["isActive"] == true
      end)
    end
  end

  describe "createCollaborator mutation" do
    test "creates collaborator when user is admin", %{conn: conn} do
      admin = create_admin_user()

      mutation = """
      mutation CreateCollaborator($input: CreateCollaboratorInput!) {
        createCollaborator(input: $input) {
          id
          name
          email
          cpf
        }
      }
      """

      input = %{
        name: "New Collaborator",
        email: "new@example.com",
        cpf: "12345678901"
      }

      conn = query_graphql(conn, mutation, %{input: input}, authenticated_context(admin))
      result = json_response(conn, 200)

      assert result["data"]["createCollaborator"]["name"] == "New Collaborator"
      assert result["data"]["createCollaborator"]["email"] == "new@example.com"
      assert result["data"]["createCollaborator"]["cpf"] == "12345678901"
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()

      mutation = """
      mutation CreateCollaborator($input: CreateCollaboratorInput!) {
        createCollaborator(input: $input) {
          id
          name
        }
      }
      """

      input = %{
        name: "New Collaborator",
        email: "new@example.com",
        cpf: "12345678901"
      }

      conn = query_graphql(conn, mutation, %{input: input}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end

    test "returns error when not authenticated", %{conn: conn} do
      mutation = """
      mutation CreateCollaborator($input: CreateCollaboratorInput!) {
        createCollaborator(input: $input) {
          id
          name
        }
      }
      """

      input = %{
        name: "New Collaborator",
        email: "new@example.com",
        cpf: "12345678901"
      }

      conn = query_graphql(conn, mutation, %{input: input}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end
  end

  describe "updateCollaborator mutation" do
    test "updates collaborator when user is admin", %{conn: conn} do
      admin = create_admin_user()
      collaborator = create_collaborator(%{name: "Old Name"})

      mutation = """
      mutation UpdateCollaborator($id: ID!, $input: UpdateCollaboratorInput!) {
        updateCollaborator(id: $id, input: $input) {
          id
          name
          email
        }
      }
      """

      input = %{name: "Updated Name", email: "updated@example.com"}

      conn =
        query_graphql(
          conn,
          mutation,
          %{id: collaborator.id, input: input},
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert result["data"]["updateCollaborator"]["name"] == "Updated Name"
      assert result["data"]["updateCollaborator"]["email"] == "updated@example.com"
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator()

      mutation = """
      mutation UpdateCollaborator($id: ID!, $input: UpdateCollaboratorInput!) {
        updateCollaborator(id: $id, input: $input) {
          id
          name
        }
      }
      """

      conn =
        query_graphql(
          conn,
          mutation,
          %{id: collaborator.id, input: %{name: "New"}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end
  end

  describe "deleteCollaborator mutation" do
    test "deletes collaborator when user is admin", %{conn: conn} do
      admin = create_admin_user()
      collaborator = create_collaborator()

      mutation = """
      mutation DeleteCollaborator($id: ID!) {
        deleteCollaborator(id: $id) {
          success
          collaborator {
            id
            name
          }
        }
      }
      """

      conn = query_graphql(conn, mutation, %{id: collaborator.id}, authenticated_context(admin))
      result = json_response(conn, 200)

      assert result["data"]["deleteCollaborator"]["success"] == true
      assert result["data"]["deleteCollaborator"]["collaborator"]["id"] == collaborator.id
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator()

      mutation = """
      mutation DeleteCollaborator($id: ID!) {
        deleteCollaborator(id: $id) {
          success
        }
      }
      """

      conn = query_graphql(conn, mutation, %{id: collaborator.id}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end
  end
end
