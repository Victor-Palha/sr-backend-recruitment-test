defmodule RecruitmentTestWeb.Graphql.TaskTest do
  use RecruitmentTestWeb.GraphQLCase
  import Phoenix.ConnTest

  describe "task query" do
    test "returns task when authenticated", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator()
      task = create_task(%{collaborator: collaborator, name: "Important Task", status: "pending"})

      query = """
      query GetTask($id: ID!) {
        task(id: $id) {
          id
          name
          description
          status
          priority
        }
      }
      """

      conn = query_graphql(conn, query, %{id: task.id}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["data"]["task"]["id"] == task.id
      assert result["data"]["task"]["name"] == "Important Task"
      assert result["data"]["task"]["status"] == "PENDING"
    end

    test "returns error when not authenticated", %{conn: conn} do
      task = create_task()

      query = """
      query GetTask($id: ID!) {
        task(id: $id) {
          id
          name
        }
      }
      """

      conn = query_graphql(conn, query, %{id: task.id}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end

    test "returns error when task not found", %{conn: conn} do
      user = create_user()

      query = """
      query GetTask($id: ID!) {
        task(id: $id) {
          id
          name
        }
      }
      """

      conn = query_graphql(conn, query, %{id: Ecto.UUID.generate()}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Task not found"
    end
  end

  describe "tasks query" do
    test "returns all tasks when authenticated", %{conn: conn} do
      user = create_user()
      _task1 = create_task(%{name: "Task One", status: "pending"})
      _task2 = create_task(%{name: "Task Two", status: "completed"})

      query = """
      query {
        tasks {
          id
          name
          status
        }
      }
      """

      conn = query_graphql(conn, query, %{}, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["tasks"]) == 2
      names = Enum.map(result["data"]["tasks"], & &1["name"])
      assert "Task One" in names
      assert "Task Two" in names
    end

    test "returns error when not authenticated", %{conn: conn} do
      query = """
      query {
        tasks {
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

  describe "createTask mutation" do
    test "creates task when user is admin", %{conn: conn} do
      admin = create_admin_user()
      collaborator = create_collaborator()

      mutation = """
      mutation CreateTask($input: CreateTaskInput!) {
        createTask(input: $input) {
          id
          name
          description
          status
          priority
        }
      }
      """

      input = %{
        name: "New Task",
        description: "Task description",
        collaboratorId: collaborator.id,
        status: "PENDING",
        priority: 3
      }

      conn = query_graphql(conn, mutation, %{input: input}, authenticated_context(admin))
      result = json_response(conn, 200)

      assert result["data"]["createTask"]["name"] == "New Task"
      assert result["data"]["createTask"]["status"] == "PENDING"
      assert result["data"]["createTask"]["priority"] == 3
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator()

      mutation = """
      mutation CreateTask($input: CreateTaskInput!) {
        createTask(input: $input) {
          id
          name
        }
      }
      """

      input = %{
        name: "New Task",
        description: "Task description",
        collaboratorId: collaborator.id,
        status: "PENDING",
        priority: 1
      }

      conn = query_graphql(conn, mutation, %{input: input}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end

    test "returns error when not authenticated", %{conn: conn} do
      collaborator = create_collaborator()

      mutation = """
      mutation CreateTask($input: CreateTaskInput!) {
        createTask(input: $input) {
          id
          name
        }
      }
      """

      input = %{
        name: "New Task",
        description: "Task description",
        collaboratorId: collaborator.id,
        status: "PENDING",
        priority: 1
      }

      conn = query_graphql(conn, mutation, %{input: input}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end
  end

  describe "updateTask mutation" do
    test "updates task when user is admin", %{conn: conn} do
      admin = create_admin_user()
      task = create_task(%{name: "Old Name", status: "pending"})

      mutation = """
      mutation UpdateTask($id: ID!, $input: UpdateTaskInput!) {
        updateTask(id: $id, input: $input) {
          id
          name
          status
          priority
        }
      }
      """

      input = %{
        name: "Updated Name",
        status: "IN_PROGRESS",
        priority: 5
      }

      conn =
        query_graphql(conn, mutation, %{id: task.id, input: input}, authenticated_context(admin))

      result = json_response(conn, 200)

      assert result["data"]["updateTask"]["name"] == "Updated Name"
      assert result["data"]["updateTask"]["status"] == "IN_PROGRESS"
      assert result["data"]["updateTask"]["priority"] == 5
    end

    test "returns error when user is not admin", %{conn: conn} do
      user = create_user()
      task = create_task()

      mutation = """
      mutation UpdateTask($id: ID!, $input: UpdateTaskInput!) {
        updateTask(id: $id, input: $input) {
          id
          name
        }
      }
      """

      conn =
        query_graphql(
          conn,
          mutation,
          %{id: task.id, input: %{name: "New"}},
          authenticated_context(user)
        )

      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Forbidden - Insufficient permissions"
    end
  end
end
