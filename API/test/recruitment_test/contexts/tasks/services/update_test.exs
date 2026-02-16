defmodule RecruitmentTest.Contexts.Tasks.Services.UpdateTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Tasks.Services.Update
  alias RecruitmentTest.Contexts.Tasks.Task
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

  describe "call/2" do
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
          name: "Original task",
          description: "Original description",
          collaborator_id: collaborator.id,
          status: "pending",
          priority: 1
        })
        |> Repo.insert()

      %{collaborator: collaborator, task: task}
    end

    test "updates a task with valid data", %{task: task} do
      attrs = %{
        name: "Updated task",
        description: "Updated description",
        status: "in_progress",
        priority: 2
      }

      assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
      assert updated_task.id == task.id
      assert updated_task.name == "Updated task"
      assert updated_task.description == "Updated description"
      assert updated_task.status == "in_progress"
      assert updated_task.priority == 2
    end

    test "updates only name", %{task: task} do
      attrs = %{
        name: "Only Name Changed"
      }

      assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
      assert updated_task.name == "Only Name Changed"
      assert updated_task.description == "Original description"
      assert updated_task.status == "pending"
      assert updated_task.priority == 1
    end

    test "updates only description", %{task: task} do
      attrs = %{
        description: "New description only"
      }

      assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
      assert updated_task.name == "Original task"
      assert updated_task.description == "New description only"
      assert updated_task.status == "pending"
      assert updated_task.priority == 1
    end

    test "updates only status", %{task: task} do
      attrs = %{
        status: "completed"
      }

      assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
      assert updated_task.name == "Original task"
      assert updated_task.description == "Original description"
      assert updated_task.status == "completed"
      assert updated_task.priority == 1
    end

    test "updates only priority", %{task: task} do
      attrs = %{
        priority: 5
      }

      assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
      assert updated_task.name == "Original task"
      assert updated_task.description == "Original description"
      assert updated_task.status == "pending"
      assert updated_task.priority == 5
    end

    test "updates with empty attrs map", %{task: task} do
      attrs = %{}

      assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
      assert updated_task.name == "Original task"
      assert updated_task.description == "Original description"
      assert updated_task.status == "pending"
      assert updated_task.priority == 1
    end

    test "does not update collaborator_id even if provided", %{
      task: task,
      collaborator: collaborator
    } do
      {:ok, another_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Jane Doe",
          email: "jane@example.com",
          cpf: "98765432100",
          is_active: true
        })
        |> Repo.insert()

      attrs = %{
        name: "Updated Name",
        collaborator_id: another_collaborator.id
      }

      assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
      assert updated_task.name == "Updated Name"
      assert updated_task.collaborator_id == collaborator.id
    end

    test "returns error when task does not exist" do
      non_existent_id = Ecto.UUID.generate()

      attrs = %{
        name: "New Name"
      }

      assert {:error, "Task not found"} = Update.call(non_existent_id, attrs)
    end

    test "returns error with invalid UUID format" do
      attrs = %{
        name: "New Name"
      }

      assert {:error, "Task not found"} = Update.call("invalid-uuid", attrs)
      assert {:error, "Task not found"} = Update.call("123", attrs)
      assert {:error, "Task not found"} = Update.call(nil, attrs)
    end

    test "returns error when name is too long", %{task: task} do
      attrs = %{
        name: String.duplicate("a", 251)
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(task.id, attrs)
      assert "should be at most 250 character(s)" in errors_on(changeset).name
    end

    test "returns error when description is too long", %{task: task} do
      attrs = %{
        description: String.duplicate("a", 5001)
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(task.id, attrs)
      assert "should be at most 5000 character(s)" in errors_on(changeset).description
    end

    test "returns error when status is invalid", %{task: task} do
      attrs = %{
        status: "invalid_status"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(task.id, attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "returns error when priority is negative", %{task: task} do
      attrs = %{
        priority: -1
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(task.id, attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).priority
    end

    test "updates task to all valid statuses", %{task: task} do
      valid_statuses = ["pending", "in_progress", "completed", "failed"]

      Enum.each(valid_statuses, fn status ->
        attrs = %{status: status}
        assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
        assert updated_task.status == status
      end)
    end

    test "clears description when set to nil", %{task: task} do
      attrs = %{
        description: nil
      }

      assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
      assert is_nil(updated_task.description)
    end

    test "updates priority to zero", %{task: task} do
      attrs = %{
        priority: 0
      }

      assert {:ok, %Task{} = updated_task} = Update.call(task.id, attrs)
      assert updated_task.priority == 0
    end
  end
end
