defmodule RecruitmentTest.Contexts.Tasks.Services.FindByIdTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Tasks.Services.FindById
  alias RecruitmentTest.Contexts.Tasks.Task
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

  describe "call/1" do
    setup do
      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "John Doe",
          email: "john@example.com",
          cpf: "12345678901",
          is_active: true
        })
        |> Repo.insert()

      {:ok, task} =
        %Task{}
        |> Task.changeset(%{
          name: "Complete project",
          description: "Finish the recruitment test",
          collaborator_id: collaborator.id,
          status: "pending",
          priority: 1
        })
        |> Repo.insert()

      %{collaborator: collaborator, task: task}
    end

    test "finds a task by valid ID", %{task: task} do
      assert {:ok, %Task{} = found_task} = FindById.call(task.id)
      assert found_task.id == task.id
      assert found_task.name == "Complete project"
      assert found_task.description == "Finish the recruitment test"
      assert found_task.status == "pending"
      assert found_task.priority == 1
    end

    test "returns error when task does not exist" do
      non_existent_id = Ecto.UUID.generate()
      assert {:error, "Task not found"} = FindById.call(non_existent_id)
    end

    test "finds task with different status", %{collaborator: collaborator} do
      {:ok, completed_task} =
        %Task{}
        |> Task.changeset(%{
          name: "Completed task",
          description: "Already done",
          collaborator_id: collaborator.id,
          status: "completed",
          priority: 3
        })
        |> Repo.insert()

      assert {:ok, %Task{} = found} = FindById.call(completed_task.id)
      assert found.status == "completed"
      assert found.priority == 3
    end

    test "finds correct task when multiple exist", %{task: first_task, collaborator: collaborator} do
      {:ok, second_task} =
        %Task{}
        |> Task.changeset(%{
          name: "Second task",
          description: "Another task",
          collaborator_id: collaborator.id,
          status: "in_progress",
          priority: 2
        })
        |> Repo.insert()

      assert {:ok, %Task{} = found_first} = FindById.call(first_task.id)
      assert found_first.id == first_task.id
      assert found_first.name == "Complete project"

      assert {:ok, %Task{} = found_second} = FindById.call(second_task.id)
      assert found_second.id == second_task.id
      assert found_second.name == "Second task"
    end

    test "finds task without description", %{collaborator: collaborator} do
      {:ok, task_no_desc} =
        %Task{}
        |> Task.changeset(%{
          name: "Task without description",
          collaborator_id: collaborator.id,
          status: "pending",
          priority: 0
        })
        |> Repo.insert()

      assert {:ok, %Task{} = found} = FindById.call(task_no_desc.id)
      assert is_nil(found.description)
    end

    test "returns error with invalid UUID format" do
      assert {:error, "Task not found"} = FindById.call("invalid-uuid")
      assert {:error, "Task not found"} = FindById.call("123")
      assert {:error, "Task not found"} = FindById.call(nil)
    end
  end
end
