defmodule RecruitmentTest.Contexts.Contracts.Services.FindByIdTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Contracts.Services.FindById
  alias RecruitmentTest.Contexts.Contracts.Contract
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

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

      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 365, :day)

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

      %{enterprise: enterprise, collaborator: collaborator, contract: contract}
    end

    test "finds a contract by valid ID", %{contract: contract} do
      assert {:ok, %Contract{} = found_contract} = FindById.call(contract.id)
      assert found_contract.id == contract.id
      assert found_contract.enterprise_id == contract.enterprise_id
      assert found_contract.collaborator_id == contract.collaborator_id
      assert found_contract.value == Decimal.new("5000.00")
      assert found_contract.status == "active"
    end

    test "returns error when contract does not exist" do
      non_existent_id = Ecto.UUID.generate()
      assert {:error, "Contract not found"} = FindById.call(non_existent_id)
    end

    test "finds contract with different status", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

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

      assert {:ok, %Contract{} = found} = FindById.call(expired_contract.id)
      assert found.status == "expired"
    end

    test "finds contract without value", %{enterprise: enterprise, collaborator: collaborator} do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      {:ok, contract_no_value} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      assert {:ok, %Contract{} = found} = FindById.call(contract_no_value.id)
      assert is_nil(found.value)
    end

    test "finds correct contract when multiple exist", %{
      contract: first_contract,
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 180, :day)

      {:ok, second_contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          value: Decimal.new("7500.00"),
          status: "active"
        })
        |> Repo.insert()

      assert {:ok, %Contract{} = found_first} = FindById.call(first_contract.id)
      assert found_first.id == first_contract.id
      assert found_first.value == Decimal.new("5000.00")

      assert {:ok, %Contract{} = found_second} = FindById.call(second_contract.id)
      assert found_second.id == second_contract.id
      assert found_second.value == Decimal.new("7500.00")
    end

    test "returns error with invalid UUID format" do
      assert {:error, "Contract not found"} = FindById.call("invalid-uuid")
      assert {:error, "Contract not found"} = FindById.call("123")
      assert {:error, "Contract not found"} = FindById.call(nil)
    end

    test "finds cancelled contract", %{enterprise: enterprise, collaborator: collaborator} do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      {:ok, cancelled_contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "cancelled"
        })
        |> Repo.insert()

      assert {:ok, %Contract{} = found} = FindById.call(cancelled_contract.id)
      assert found.status == "cancelled"
    end
  end
end
