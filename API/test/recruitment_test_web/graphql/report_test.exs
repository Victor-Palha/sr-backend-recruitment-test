defmodule RecruitmentTestWeb.Graphql.ReportTest do
  use RecruitmentTestWeb.GraphQLCase
  import Phoenix.ConnTest

  describe "report query" do
    test "returns report when authenticated", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator(%{name: "Jane Doe"})
      task = create_task(%{collaborator: collaborator, name: "Completed Task"})
      report = create_report(%{collaborator: collaborator, task: task})

      query = """
      query GetReport($id: ID!) {
        report(id: $id) {
          id
          taskName
          taskDescription
          collaboratorName
          completedAt
        }
      }
      """

      conn = query_graphql(conn, query, %{id: report.id}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["data"]["report"]["id"] == report.id
      assert result["data"]["report"]["taskName"] == "Completed Task"
      assert result["data"]["report"]["collaboratorName"] == "Jane Doe"
    end

    test "returns error when not authenticated", %{conn: conn} do
      report = create_report()

      query = """
      query GetReport($id: ID!) {
        report(id: $id) {
          id
          taskName
        }
      }
      """

      conn = query_graphql(conn, query, %{id: report.id}, %{})
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Unauthorized - Invalid or missing token"
    end

    test "returns error when report not found", %{conn: conn} do
      user = create_user()

      query = """
      query GetReport($id: ID!) {
        report(id: $id) {
          id
          taskName
        }
      }
      """

      conn = query_graphql(conn, query, %{id: Ecto.UUID.generate()}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["errors"]
      assert hd(result["errors"])["message"] == "Report not found"
    end
  end

  describe "reports query" do
    test "returns all reports when authenticated", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator()
      task1 = create_task(%{collaborator: collaborator, name: "Task One"})
      task2 = create_task(%{collaborator: collaborator, name: "Task Two"})
      _report1 = create_report(%{collaborator: collaborator, task: task1})
      _report2 = create_report(%{collaborator: collaborator, task: task2})

      query = """
      query {
        reports {
          data {
            id
            taskName
            collaboratorName
          }
          pageInfo {
            totalCount
          }
        }
      }
      """

      conn = query_graphql(conn, query, %{}, authenticated_context(user))
      result = json_response(conn, 200)

      assert length(result["data"]["reports"]["data"]) == 2
      task_names = Enum.map(result["data"]["reports"]["data"], & &1["taskName"])
      assert "Task One" in task_names
      assert "Task Two" in task_names
    end

    test "returns error when not authenticated", %{conn: conn} do
      query = """
      query {
        reports {
          data {
            id
            taskName
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

  describe "reports query with pagination" do
    test "returns paginated reports", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator()

      for i <- 1..8 do
        task = create_task(%{collaborator: collaborator, name: "Task #{i}"})
        create_report(%{collaborator: collaborator, task: task})
      end

      query = """
      query GetReports($pagination: PaginationInput) {
        reports(pagination: $pagination) {
          data {
            id
            taskName
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

      assert length(result["data"]["reports"]["data"]) == 5
      assert result["data"]["reports"]["pageInfo"]["hasNextPage"] == true
      assert result["data"]["reports"]["pageInfo"]["totalCount"] == 8
    end
  end

  describe "reports with nested data" do
    test "returns report with collaborator and task associations", %{conn: conn} do
      user = create_user()
      collaborator = create_collaborator(%{name: "John Smith"})
      task = create_task(%{collaborator: collaborator, name: "Important Task"})
      report = create_report(%{collaborator: collaborator, task: task})

      query = """
      query GetReport($id: ID!) {
        report(id: $id) {
          id
          taskName
          collaboratorName
          collaborator {
            id
            name
            email
          }
          task {
            id
            name
            status
          }
        }
      }
      """

      conn = query_graphql(conn, query, %{id: report.id}, authenticated_context(user))
      result = json_response(conn, 200)

      assert result["data"]["report"]["id"] == report.id
      assert result["data"]["report"]["collaborator"]["id"] == collaborator.id
      assert result["data"]["report"]["collaborator"]["name"] == "John Smith"
      assert result["data"]["report"]["task"]["id"] == task.id
      assert result["data"]["report"]["task"]["name"] == "Important Task"
    end
  end
end
