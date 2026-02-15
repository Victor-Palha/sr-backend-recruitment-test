defmodule RecruitmentTestWeb.Graphql.UserTest do
  use RecruitmentTestWeb.GraphQLCase
  import Phoenix.ConnTest

  describe "user query" do
    test "returns user when authenticated", %{conn: conn} do
      admin = create_admin_user()
      user = create_user(%{name: "Jane Doe", email: "jane@example.com"})

      query = """
      query GetUser($id: ID!) {
        user(id: $id) {
          id
          name
          email
          role
          isActive
          insertedAt
          updatedAt
        }
      }
      """

      conn = query_graphql(conn, query, %{id: user.id}, authenticated_context(admin))
      result = json_response(conn, 200)

      assert result["data"]["user"]["id"] == user.id
      assert result["data"]["user"]["name"] == "Jane Doe"
      assert result["data"]["user"]["email"] == "jane@example.com"
      assert result["data"]["user"]["role"] == "USER"
      assert result["data"]["user"]["isActive"] == true
      assert result["data"]["user"]["insertedAt"]
      assert result["data"]["user"]["updatedAt"]
    end

    test "returns error when not authenticated", %{conn: conn} do
      user = create_user()

      query = """
      query GetUser($id: ID!) {
        user(id: $id) {
          id
          name
        }
      }
      """

      conn = query_graphql(conn, query, %{id: user.id}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end

    test "returns error when user not found", %{conn: conn} do
      user = create_user()

      query = """
      query GetUser($id: ID!) {
        user(id: $id) {
          id
          name
        }
      }
      """

      conn = query_graphql(conn, query, %{id: Ecto.UUID.generate()}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "User not found"
    end
  end

  describe "users query" do
    test "returns all users when authenticated", %{conn: conn} do
      admin = create_admin_user(%{name: "Admin User"})
      _user1 = create_user(%{name: "Alice"})
      _user2 = create_user(%{name: "Bob"})

      query = """
      query {
        users {
          data {
            id
            name
            email
            role
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

      conn = query_graphql(conn, query, %{}, authenticated_context(admin))
      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 3
      names = Enum.map(result["data"]["users"]["data"], & &1["name"])
      assert "Alice" in names
      assert "Bob" in names
      assert "Admin User" in names
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 3
    end

    test "returns error when not authenticated", %{conn: conn} do
      query = """
      query {
        users {
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

  describe "users query with pagination" do
    test "returns paginated users", %{conn: conn} do
      admin = create_admin_user()

      for i <- 1..14 do
        create_user(%{name: "User #{String.pad_leading(to_string(i), 2, "0")}"})
      end

      query = """
      query GetUsers($pagination: PaginationInput) {
        users(pagination: $pagination) {
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
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 5
      assert result["data"]["users"]["pageInfo"]["hasNextPage"] == true
      assert result["data"]["users"]["pageInfo"]["hasPreviousPage"] == false
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 15
    end

    test "returns second page correctly", %{conn: conn} do
      admin = create_admin_user()

      for i <- 1..14 do
        create_user(%{name: "User #{String.pad_leading(to_string(i), 2, "0")}"})
      end

      query = """
      query GetUsers($pagination: PaginationInput) {
        users(pagination: $pagination) {
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
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 5
      assert result["data"]["users"]["pageInfo"]["hasNextPage"] == true
      assert result["data"]["users"]["pageInfo"]["hasPreviousPage"] == true
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 15
    end

    test "returns last page correctly", %{conn: conn} do
      admin = create_admin_user()

      for i <- 1..14 do
        create_user(%{name: "User #{String.pad_leading(to_string(i), 2, "0")}"})
      end

      query = """
      query GetUsers($pagination: PaginationInput) {
        users(pagination: $pagination) {
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
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 5
      assert result["data"]["users"]["pageInfo"]["hasNextPage"] == false
      assert result["data"]["users"]["pageInfo"]["hasPreviousPage"] == true
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 15
    end

    test "returns empty data for page beyond total", %{conn: conn} do
      admin = create_admin_user()

      query = """
      query GetUsers($pagination: PaginationInput) {
        users(pagination: $pagination) {
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
          %{pagination: %{page: 100, pageSize: 10}},
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert result["data"]["users"]["data"] == []
      assert result["data"]["users"]["pageInfo"]["hasNextPage"] == false
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 1
    end
  end

  describe "users query with filters" do
    test "filters by name", %{conn: conn} do
      admin = create_admin_user()
      _user1 = create_user(%{name: "Alice Smith"})
      _user2 = create_user(%{name: "Bob Jones"})
      _user3 = create_user(%{name: "Alice Johnson"})

      query = """
      query GetUsers($filters: UserFilters) {
        users(filters: $filters) {
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

      conn =
        query_graphql(conn, query, %{filters: %{name: "Alice"}}, authenticated_context(admin))

      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 2
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 2
      names = Enum.map(result["data"]["users"]["data"], & &1["name"])
      assert "Alice Smith" in names
      assert "Alice Johnson" in names
    end

    test "filters by email", %{conn: conn} do
      admin = create_admin_user()
      _user1 = create_user(%{name: "Alice", email: "alice@company.com"})
      _user2 = create_user(%{name: "Bob", email: "bob@othercompany.com"})
      _user3 = create_user(%{name: "Charlie", email: "charlie@company.com"})

      query = """
      query GetUsers($filters: UserFilters) {
        users(filters: $filters) {
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
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 2
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 2
      names = Enum.map(result["data"]["users"]["data"], & &1["name"])
      assert "Alice" in names
      assert "Charlie" in names
    end

    test "filters by role", %{conn: conn} do
      admin = create_admin_user(%{name: "Admin 1"})
      _admin2 = create_admin_user(%{name: "Admin 2"})
      _user1 = create_user(%{name: "Regular User"})

      query = """
      query GetUsers($filters: UserFilters) {
        users(filters: $filters) {
          data {
            id
            name
            role
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn =
        query_graphql(conn, query, %{filters: %{role: "ADMIN"}}, authenticated_context(admin))

      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 2
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 2

      roles = Enum.map(result["data"]["users"]["data"], & &1["role"])
      assert Enum.all?(roles, &(&1 == "ADMIN"))
    end

    test "filters by isActive", %{conn: conn} do
      admin = create_admin_user()
      _user1 = create_user(%{name: "Active User", is_active: true})
      _user2 = create_user(%{name: "Inactive User", is_active: false})
      _user3 = create_user(%{name: "Another Active", is_active: true})

      query = """
      query GetUsers($filters: UserFilters) {
        users(filters: $filters) {
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
        query_graphql(conn, query, %{filters: %{isActive: false}}, authenticated_context(admin))

      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 1
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 1
      assert hd(result["data"]["users"]["data"])["name"] == "Inactive User"
      assert hd(result["data"]["users"]["data"])["isActive"] == false
    end

    test "combines multiple filters", %{conn: conn} do
      admin = create_admin_user()

      _user1 =
        create_user(%{
          name: "Alice Active",
          email: "alice.active@company.com",
          is_active: true,
          role: "user"
        })

      _user2 =
        create_user(%{
          name: "Alice Inactive",
          email: "alice.inactive@company.com",
          is_active: false,
          role: "user"
        })

      _user3 =
        create_user(%{
          name: "Bob Active",
          email: "bob.active@company.com",
          is_active: true,
          role: "user"
        })

      query = """
      query GetUsers($filters: UserFilters) {
        users(filters: $filters) {
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
        query_graphql(
          conn,
          query,
          %{filters: %{name: "Alice", isActive: true}},
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 1
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 1
      assert hd(result["data"]["users"]["data"])["name"] == "Alice Active"
    end
  end

  describe "users query with pagination and filters" do
    test "returns filtered and paginated results", %{conn: conn} do
      admin = create_admin_user()

      for i <- 1..8 do
        create_user(%{
          name: "Active User #{String.pad_leading(to_string(i), 2, "0")}",
          is_active: true
        })
      end

      for i <- 1..4 do
        create_user(%{name: "Inactive User #{i}", is_active: false})
      end

      query = """
      query GetUsers($pagination: PaginationInput, $filters: UserFilters) {
        users(pagination: $pagination, filters: $filters) {
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

      conn =
        query_graphql(
          conn,
          query,
          %{pagination: %{page: 1, pageSize: 5}, filters: %{isActive: true}},
          authenticated_context(admin)
        )

      result = json_response(conn, 200)

      assert length(result["data"]["users"]["data"]) == 5
      assert result["data"]["users"]["pageInfo"]["totalCount"] == 9
      assert result["data"]["users"]["pageInfo"]["hasNextPage"] == true
      assert result["data"]["users"]["pageInfo"]["hasPreviousPage"] == false

      assert Enum.all?(result["data"]["users"]["data"], &(&1["isActive"] == true))
    end
  end
end
