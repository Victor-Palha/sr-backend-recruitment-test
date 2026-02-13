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
          id
          name
          email
        }
      }
      """

      conn = query_graphql(conn, query, %{}, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["collaborators"]) == 2
      names = Enum.map(result["data"]["collaborators"], & &1["name"])
      assert "Alice" in names
      assert "Bob" in names
    end

    test "returns error when not authenticated", %{conn: conn} do
      query = """
      query {
        collaborators {
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
