defmodule RecruitmentTest.Contexts.Tasks.Services.CreateTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Tasks.Services.Create
  alias RecruitmentTest.Contexts.Tasks.Task
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Contexts.Contracts.Contract

  describe "call/1" do
    setup do
      {:ok, enterprise} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Test Corp",
          commercial_name: "Test Corporation",
          cnpj: "12345678000190",
          description: "Test enterprise"
        })
        |> Repo.insert()

      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "John Doe",
          email: "john@example.com",
          cpf: "12345678901",
          is_active: true
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now() |> DateTime.add(-1, :day)
      expires_at = DateTime.utc_now() |> DateTime.add(30, :day)

      {:ok, contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      %{
        enterprise: enterprise,
        collaborator: collaborator,
        contract: contract
      }
    end

    test "creates a task successfully with valid data", %{collaborator: collaborator} do
      attrs = %{
        name: "Implement feature",
        description: "Implement the new authentication feature",
        collaborator_id: collaborator.id,
        status: "pending",
        priority: 1
      }

      assert {:ok, %Task{} = task} = Create.call(attrs)
      assert task.name == "Implement feature"
      assert task.description == "Implement the new authentication feature"
      assert task.collaborator_id == collaborator.id
      assert task.status == "pending"
      assert task.priority == 1
      assert task.id
      assert task.inserted_at
      assert task.updated_at
    end

    test "creates a task without description", %{collaborator: collaborator} do
      attrs = %{
        name: "Quick task",
        collaborator_id: collaborator.id,
        status: "pending",
        priority: 0
      }

      assert {:ok, %Task{} = task} = Create.call(attrs)
      assert is_nil(task.description)
    end

    test "creates a task with default status", %{collaborator: collaborator} do
      attrs = %{
        name: "Task with defaults",
        collaborator_id: collaborator.id
      }

      assert {:ok, %Task{} = task} = Create.call(attrs)
      assert task.status == "pending"
      assert task.priority == 0
    end

    test "creates a task with in_progress status", %{collaborator: collaborator} do
      attrs = %{
        name: "In progress task",
        collaborator_id: collaborator.id,
        status: "in_progress",
        priority: 2
      }

      assert {:ok, %Task{} = task} = Create.call(attrs)
      assert task.status == "in_progress"
    end

    test "creates a task with completed status", %{collaborator: collaborator} do
      attrs = %{
        name: "Completed task",
        collaborator_id: collaborator.id,
        status: "completed",
        priority: 3
      }

      assert {:ok, %Task{} = task} = Create.call(attrs)
      assert task.status == "completed"
    end

    test "creates a task with failed status", %{collaborator: collaborator} do
      attrs = %{
        name: "Failed task",
        collaborator_id: collaborator.id,
        status: "failed",
        priority: 1
      }

      assert {:ok, %Task{} = task} = Create.call(attrs)
      assert task.status == "failed"
    end

    test "creates a task with high priority", %{collaborator: collaborator} do
      attrs = %{
        name: "High priority task",
        collaborator_id: collaborator.id,
        status: "pending",
        priority: 100
      }

      assert {:ok, %Task{} = task} = Create.call(attrs)
      assert task.priority == 100
    end

    test "returns error when collaborator does not exist" do
      attrs = %{
        name: "Task for nonexistent collaborator",
        collaborator_id: Ecto.UUID.generate(),
        status: "pending",
        priority: 1
      }

      assert {:error, "Collaborator not found"} = Create.call(attrs)
    end

    test "returns error when collaborator is not active", %{
      enterprise: enterprise
    } do
      {:ok, inactive_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Inactive User",
          email: "inactive@example.com",
          cpf: "98765432100",
          is_active: false
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now() |> DateTime.add(-1, :day)
      expires_at = DateTime.utc_now() |> DateTime.add(30, :day)

      %Contract{}
      |> Contract.changeset(%{
        enterprise_id: enterprise.id,
        collaborator_id: inactive_collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      })
      |> Repo.insert()

      attrs = %{
        name: "Task for inactive collaborator",
        collaborator_id: inactive_collaborator.id,
        status: "pending",
        priority: 1
      }

      assert {:error, "Collaborator is not active"} = Create.call(attrs)
    end

    test "returns error when name is missing", %{collaborator: collaborator} do
      attrs = %{
        description: "Task without name",
        collaborator_id: collaborator.id,
        status: "pending",
        priority: 1
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error when collaborator_id is missing" do
      attrs = %{
        name: "Task without collaborator",
        status: "pending",
        priority: 1
      }

      assert {:error, "Collaborator not found"} = Create.call(attrs)
    end

    test "returns error when status is invalid", %{collaborator: collaborator} do
      attrs = %{
        name: "Task with invalid status",
        collaborator_id: collaborator.id,
        status: "invalid_status",
        priority: 1
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "returns error when priority is negative", %{collaborator: collaborator} do
      attrs = %{
        name: "Task with negative priority",
        collaborator_id: collaborator.id,
        status: "pending",
        priority: -1
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).priority
    end

    test "returns error when name exceeds max length", %{collaborator: collaborator} do
      attrs = %{
        name: String.duplicate("a", 251),
        collaborator_id: collaborator.id,
        status: "pending",
        priority: 1
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "should be at most 250 character(s)" in errors_on(changeset).name
    end

    test "returns error when description exceeds max length", %{collaborator: collaborator} do
      attrs = %{
        name: "Task with long description",
        description: String.duplicate("a", 5001),
        collaborator_id: collaborator.id,
        status: "pending",
        priority: 1
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "should be at most 5000 character(s)" in errors_on(changeset).description
    end

    test "creates multiple tasks for the same collaborator", %{collaborator: collaborator} do
      attrs_1 = %{
        name: "First task",
        collaborator_id: collaborator.id,
        status: "pending",
        priority: 1
      }

      attrs_2 = %{
        name: "Second task",
        collaborator_id: collaborator.id,
        status: "in_progress",
        priority: 2
      }

      assert {:ok, %Task{} = task_1} = Create.call(attrs_1)
      assert {:ok, %Task{} = task_2} = Create.call(attrs_2)
      assert task_1.id != task_2.id
    end

    test "creates task with contract that started today" do
      {:ok, enterprise} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Today Corp",
          commercial_name: "Today Corporation",
          cnpj: "33344455566600",
          description: "Today enterprise"
        })
        |> Repo.insert()

      {:ok, today_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Today User",
          email: "today@example.com",
          cpf: "44455566677",
          is_active: true
        })
        |> Repo.insert()

      now = DateTime.utc_now()
      starts_at = DateTime.truncate(now, :second)
      expires_at = DateTime.add(now, 30, :day)

      %Contract{}
      |> Contract.changeset(%{
        enterprise_id: enterprise.id,
        collaborator_id: today_collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      })
      |> Repo.insert()

      attrs = %{
        name: "Task for today's contract",
        collaborator_id: today_collaborator.id,
        status: "pending",
        priority: 1
      }

      assert {:ok, %Task{}} = Create.call(attrs)
    end
  end
end
