defmodule RecruitmentTest.Contexts.Collaborators.Services.DeleteTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Collaborators.Services.Delete
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Contexts.Contracts.Contract
  alias RecruitmentTest.Contexts.Tasks.Task

  describe "call/1" do
    test "soft deletes a collaborator by setting is_active to false" do
      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "John Doe",
          email: "john@example.com",
          cpf: "12345678901",
          is_active: true
        })
        |> Repo.insert()

      assert {:ok, deactivated_collaborator} = Delete.call(collaborator.id)
      assert deactivated_collaborator.id == collaborator.id
      assert deactivated_collaborator.name == "John Doe"
      assert deactivated_collaborator.is_active == false

      # Verify collaborator still exists in database
      persisted = Repo.get(Collaborator, collaborator.id)
      assert persisted != nil
      assert persisted.is_active == false
    end

    test "returns error when collaborator does not exist" do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, "Collaborator not found"} = Delete.call(non_existent_id)
    end

    test "soft deletes collaborator with active contracts" do
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

      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

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

      assert {:ok, deactivated} = Delete.call(collaborator.id)
      assert deactivated.is_active == false

      # Verify collaborator still exists
      assert Repo.get(Collaborator, collaborator.id) != nil

      # Verify contract still exists
      assert Repo.get(Contract, contract.id) != nil
    end

    test "soft deletes collaborator with open tasks" do
      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Jane Doe",
          email: "jane@example.com",
          cpf: "98765432100",
          is_active: true
        })
        |> Repo.insert()

      {:ok, task} =
        %Task{}
        |> Task.changeset(%{
          name: "Test Task",
          description: "Test task description",
          collaborator_id: collaborator.id,
          status: "pending",
          priority: 1
        })
        |> Repo.insert()

      assert {:ok, deactivated} = Delete.call(collaborator.id)
      assert deactivated.is_active == false

      # Verify collaborator still exists
      assert Repo.get(Collaborator, collaborator.id) != nil

      # Verify task still exists
      assert Repo.get(Task, task.id) != nil
    end

    test "soft deletes collaborator with both active contracts and open tasks" do
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
          name: "Full User",
          email: "full@example.com",
          cpf: "11111111111",
          is_active: true
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

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

      {:ok, task} =
        %Task{}
        |> Task.changeset(%{
          name: "Test Task",
          collaborator_id: collaborator.id,
          status: "pending",
          priority: 1
        })
        |> Repo.insert()

      assert {:ok, deactivated} = Delete.call(collaborator.id)
      assert deactivated.is_active == false

      # Verify collaborator still exists
      assert Repo.get(Collaborator, collaborator.id) != nil

      # Verify contract and task still exist
      assert Repo.get(Contract, contract.id) != nil
      assert Repo.get(Task, task.id) != nil
    end

    test "soft deletes multiple collaborators independently" do
      {:ok, collaborator1} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "First User",
          email: "first@example.com",
          cpf: "11111111111",
          is_active: true
        })
        |> Repo.insert()

      {:ok, collaborator2} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Second User",
          email: "second@example.com",
          cpf: "22222222222",
          is_active: true
        })
        |> Repo.insert()

      assert {:ok, deactivated1} = Delete.call(collaborator1.id)
      assert deactivated1.is_active == false

      assert {:ok, deactivated2} = Delete.call(collaborator2.id)
      assert deactivated2.is_active == false

      # Verify both still exist in database but are inactive
      assert Repo.get(Collaborator, collaborator1.id).is_active == false
      assert Repo.get(Collaborator, collaborator2.id).is_active == false
    end

    test "returns error with invalid UUID format" do
      assert {:error, "Collaborator not found"} = Delete.call("invalid-uuid")
    end

    test "returns error with nil ID" do
      assert {:error, "Collaborator not found"} = Delete.call(nil)
    end

    test "returns error with empty string ID" do
      assert {:error, "Collaborator not found"} = Delete.call("")
    end

    test "soft deletes inactive collaborator" do
      {:ok, inactive_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Inactive User",
          email: "inactive@example.com",
          cpf: "33333333333",
          is_active: false
        })
        |> Repo.insert()

      assert {:ok, deactivated} = Delete.call(inactive_collaborator.id)
      assert deactivated.is_active == false
      assert Repo.get(Collaborator, inactive_collaborator.id) != nil
    end

    test "soft deletes active collaborator without dependencies" do
      {:ok, active_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Active User",
          email: "active@example.com",
          cpf: "44444444444",
          is_active: true
        })
        |> Repo.insert()

      assert {:ok, deactivated} = Delete.call(active_collaborator.id)
      assert deactivated.is_active == false
      assert Repo.get(Collaborator, active_collaborator.id) != nil
    end

    test "returns error when trying to delete already deleted collaborator" do
      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "John Doe",
          email: "john@example.com",
          cpf: "55555555555",
          is_active: true
        })
        |> Repo.insert()

      # Delete the collaborator
      assert {:ok, _deactivated} = Delete.call(collaborator.id)

      # Try to delete again - should still work (idempotent)
      assert {:ok, deactivated_again} = Delete.call(collaborator.id)
      assert deactivated_again.is_active == false
    end

    test "can soft delete one collaborator while others exist" do
      {:ok, collaborator1} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "First User",
          email: "first@example.com",
          cpf: "11111111111",
          is_active: true
        })
        |> Repo.insert()

      {:ok, collaborator2} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Second User",
          email: "second@example.com",
          cpf: "22222222222",
          is_active: true
        })
        |> Repo.insert()

      # Delete first collaborator
      assert {:ok, _deactivated} = Delete.call(collaborator1.id)
      assert Repo.get(Collaborator, collaborator1.id).is_active == false

      # Second collaborator still active
      assert Repo.get(Collaborator, collaborator2.id).is_active == true
    end

    test "soft deletes collaborator with expired contracts" do
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
          name: "Expired Contract User",
          email: "expired@example.com",
          cpf: "66666666666",
          is_active: true
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now() |> DateTime.add(-60, :day)
      expires_at = DateTime.utc_now() |> DateTime.add(-1, :day)

      {:ok, contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "expired"
        })
        |> Repo.insert()

      assert {:ok, deactivated} = Delete.call(collaborator.id)
      assert deactivated.is_active == false
      assert Repo.get(Collaborator, collaborator.id) != nil

      # Verify contract still exists
      assert Repo.get(Contract, contract.id) != nil
    end

    test "soft deletes collaborator with cancelled contracts" do
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
          name: "Cancelled Contract User",
          email: "cancelled@example.com",
          cpf: "77777777777",
          is_active: true
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now() |> DateTime.add(-10, :day)
      expires_at = DateTime.utc_now() |> DateTime.add(20, :day)

      {:ok, contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "cancelled"
        })
        |> Repo.insert()

      assert {:ok, deactivated} = Delete.call(collaborator.id)
      assert deactivated.is_active == false
      assert Repo.get(Collaborator, collaborator.id) != nil

      # Verify contract still exists
      assert Repo.get(Contract, contract.id) != nil
    end

    test "soft deletes collaborator with completed tasks" do
      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Completed Tasks User",
          email: "completed@example.com",
          cpf: "88888888888",
          is_active: true
        })
        |> Repo.insert()

      {:ok, task} =
        %Task{}
        |> Task.changeset(%{
          name: "Completed Task",
          description: "This task is completed",
          collaborator_id: collaborator.id,
          status: "completed",
          priority: 1
        })
        |> Repo.insert()

      assert {:ok, deactivated} = Delete.call(collaborator.id)
      assert deactivated.is_active == false
      assert Repo.get(Collaborator, collaborator.id) != nil

      # Verify task still exists
      assert Repo.get(Task, task.id) != nil
    end

    test "soft deletes collaborator with in_progress tasks" do
      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "In Progress User",
          email: "inprogress@example.com",
          cpf: "10101010101",
          is_active: true
        })
        |> Repo.insert()

      {:ok, task} =
        %Task{}
        |> Task.changeset(%{
          name: "In Progress Task",
          collaborator_id: collaborator.id,
          status: "in_progress",
          priority: 1
        })
        |> Repo.insert()

      assert {:ok, deactivated} = Delete.call(collaborator.id)
      assert deactivated.is_active == false
      assert Repo.get(Collaborator, collaborator.id) != nil

      # Verify task still exists
      assert Repo.get(Task, task.id) != nil
    end

    test "soft deletes collaborator with multiple active contracts" do
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
          name: "Multi Contract User",
          email: "multi@example.com",
          cpf: "20202020202",
          is_active: true
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      {:ok, contract1} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      {:ok, contract2} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      assert {:ok, deactivated} = Delete.call(collaborator.id)
      assert deactivated.is_active == false
      assert Repo.get(Collaborator, collaborator.id) != nil

      assert Repo.get(Contract, contract1.id) != nil
      assert Repo.get(Contract, contract2.id) != nil
    end
  end
end
