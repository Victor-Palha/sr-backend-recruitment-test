defmodule RecruitmentTest.Contexts.Contracts.Services.DeleteTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Contracts.Services.Delete
  alias RecruitmentTest.Contexts.Contracts.Contract
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Contexts.Tasks.Task

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
          value: Decimal.new("5000.00"),
          status: "active"
        })
        |> Repo.insert()

      %{
        enterprise: enterprise,
        collaborator: collaborator,
        contract: contract
      }
    end

    test "deletes a contract successfully when it has no tasks", %{contract: contract} do
      assert {:ok, %Contract{} = deleted_contract} = Delete.call(contract.id)
      assert deleted_contract.id == contract.id
      assert is_nil(Repo.get(Contract, contract.id))
    end

    test "returns error when contract does not exist" do
      non_existent_id = Ecto.UUID.generate()
      assert {:error, "Contract not found"} = Delete.call(non_existent_id)
    end

    test "returns error with invalid UUID format" do
      assert {:error, "Contract not found"} = Delete.call("invalid-uuid")
    end

    test "returns error with nil ID" do
      assert {:error, "Contract not found"} = Delete.call(nil)
    end

    test "returns error with empty string ID" do
      assert {:error, "Contract not found"} = Delete.call("")
    end

    test "returns error when contract has associated tasks", %{
      contract: contract,
      collaborator: collaborator
    } do
      %Task{}
      |> Task.changeset(%{
        name: "Test Task",
        description: "Test task description",
        collaborator_id: collaborator.id,
        status: "pending",
        priority: 1
      })
      |> Repo.insert()

      assert {:error, "Cannot delete contract with existing tasks for the collaborator"} =
               Delete.call(contract.id)

      assert Repo.get(Contract, contract.id)
    end

    test "deletes contract even if it has expired status", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now() |> DateTime.add(-60, :day)
      expires_at = DateTime.utc_now() |> DateTime.add(-1, :day)

      {:ok, expired_contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "expired"
        })
        |> Repo.insert()

      assert {:ok, %Contract{}} = Delete.call(expired_contract.id)
      assert is_nil(Repo.get(Contract, expired_contract.id))
    end

    test "deletes contract even if it has cancelled status", %{
      enterprise: enterprise
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

      starts_at = DateTime.utc_now() |> DateTime.add(-10, :day)
      expires_at = DateTime.utc_now() |> DateTime.add(20, :day)

      {:ok, cancelled_contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: another_collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "cancelled"
        })
        |> Repo.insert()

      assert {:ok, %Contract{}} = Delete.call(cancelled_contract.id)
      assert is_nil(Repo.get(Contract, cancelled_contract.id))
    end

    test "deletes contract without value", %{enterprise: enterprise} do
      {:ok, no_value_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "No Value User",
          email: "novalue@example.com",
          cpf: "11122233344",
          is_active: true
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now() |> DateTime.add(-1, :day)
      expires_at = DateTime.utc_now() |> DateTime.add(30, :day)

      {:ok, contract_without_value} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: no_value_collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      assert {:ok, %Contract{}} = Delete.call(contract_without_value.id)
      assert is_nil(Repo.get(Contract, contract_without_value.id))
    end

    test "can delete one contract while others exist for different collaborators", %{
      enterprise: enterprise,
      contract: first_contract
    } do
      {:ok, second_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Jane Doe",
          email: "jane@example.com",
          cpf: "55566677788",
          is_active: true
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now() |> DateTime.add(-1, :day)
      expires_at = DateTime.utc_now() |> DateTime.add(30, :day)

      {:ok, second_contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: second_collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      assert {:ok, %Contract{}} = Delete.call(first_contract.id)
      assert is_nil(Repo.get(Contract, first_contract.id))

      assert Repo.get(Contract, second_contract.id)
    end

    test "returns error when trying to delete already deleted contract", %{contract: contract} do
      assert {:ok, %Contract{}} = Delete.call(contract.id)

      assert {:error, "Contract not found"} = Delete.call(contract.id)
    end

    test "returns error when collaborator has multiple tasks", %{
      contract: contract,
      collaborator: collaborator
    } do
      %Task{}
      |> Task.changeset(%{
        name: "Task 1",
        collaborator_id: collaborator.id,
        status: "pending",
        priority: 1
      })
      |> Repo.insert()

      %Task{}
      |> Task.changeset(%{
        name: "Task 2",
        collaborator_id: collaborator.id,
        status: "in_progress",
        priority: 2
      })
      |> Repo.insert()

      assert {:error, "Cannot delete contract with existing tasks for the collaborator"} =
               Delete.call(contract.id)

      assert Repo.get(Contract, contract.id)
    end
  end
end
