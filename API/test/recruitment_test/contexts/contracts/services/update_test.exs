defmodule RecruitmentTest.Contexts.Contracts.Services.UpdateTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Contracts.Services.Update
  alias RecruitmentTest.Contexts.Contracts.Contract
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

  describe "call/2" do
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

    test "updates a contract with valid data", %{contract: contract} do
      new_starts_at = DateTime.utc_now() |> DateTime.add(-2, :day)
      new_expires_at = DateTime.utc_now() |> DateTime.add(60, :day)

      attrs = %{
        value: Decimal.new("7000.00"),
        starts_at: new_starts_at,
        expires_at: new_expires_at,
        status: "active"
      }

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert updated_contract.id == contract.id
      assert updated_contract.value == Decimal.new("7000.00")
      assert updated_contract.status == "active"
    end

    test "updates only value", %{contract: contract} do
      attrs = %{
        value: Decimal.new("6000.00")
      }

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert updated_contract.value == Decimal.new("6000.00")
      assert updated_contract.status == contract.status
    end

    test "updates only status", %{contract: contract} do
      attrs = %{
        status: "expired"
      }

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert updated_contract.status == "expired"
      assert updated_contract.value == contract.value
    end

    test "updates status to cancelled", %{contract: contract} do
      attrs = %{
        status: "cancelled"
      }

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert updated_contract.status == "cancelled"
    end

    test "updates dates", %{contract: contract} do
      new_starts_at = DateTime.utc_now() |> DateTime.add(-5, :day) |> DateTime.truncate(:second)
      new_expires_at = DateTime.utc_now() |> DateTime.add(90, :day) |> DateTime.truncate(:second)

      attrs = %{
        starts_at: new_starts_at,
        expires_at: new_expires_at
      }

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert DateTime.compare(updated_contract.starts_at, new_starts_at) == :eq
      assert DateTime.compare(updated_contract.expires_at, new_expires_at) == :eq
    end

    test "sets value to nil", %{contract: contract} do
      attrs = %{
        value: nil
      }

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert is_nil(updated_contract.value)
    end

    test "updates with empty attrs map", %{contract: contract} do
      attrs = %{}

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert updated_contract.value == contract.value
      assert updated_contract.status == contract.status
    end

    test "does not update enterprise_id even if provided", %{contract: contract} do
      new_enterprise_id = Ecto.UUID.generate()

      attrs = %{
        enterprise_id: new_enterprise_id,
        value: Decimal.new("8000.00")
      }

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert updated_contract.value == Decimal.new("8000.00")
      assert updated_contract.enterprise_id == contract.enterprise_id
      assert updated_contract.enterprise_id != new_enterprise_id
    end

    test "does not update collaborator_id even if provided", %{contract: contract} do
      new_collaborator_id = Ecto.UUID.generate()

      attrs = %{
        collaborator_id: new_collaborator_id,
        value: Decimal.new("9000.00")
      }

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert updated_contract.value == Decimal.new("9000.00")
      assert updated_contract.collaborator_id == contract.collaborator_id
      assert updated_contract.collaborator_id != new_collaborator_id
    end

    test "returns error when contract does not exist" do
      non_existent_id = Ecto.UUID.generate()

      attrs = %{
        value: Decimal.new("5000.00")
      }

      assert {:error, "Contract not found"} = Update.call(non_existent_id, attrs)
    end

    test "returns error with invalid UUID format" do
      attrs = %{
        value: Decimal.new("5000.00")
      }

      assert {:error, "Contract not found"} = Update.call("invalid-uuid", attrs)
    end

    test "returns error with nil ID" do
      attrs = %{
        value: Decimal.new("5000.00")
      }

      assert {:error, "Contract not found"} = Update.call(nil, attrs)
    end

    test "returns error with empty string ID" do
      attrs = %{
        value: Decimal.new("5000.00")
      }

      assert {:error, "Contract not found"} = Update.call("", attrs)
    end

    test "returns error when status is invalid", %{contract: contract} do
      attrs = %{
        status: "invalid_status"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(contract.id, attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "returns error when expires_at is before starts_at", %{contract: contract} do
      new_starts_at = DateTime.utc_now()
      new_expires_at = DateTime.utc_now() |> DateTime.add(-1, :day)

      attrs = %{
        starts_at: new_starts_at,
        expires_at: new_expires_at
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(contract.id, attrs)
      assert "must be after starts_at" in errors_on(changeset).expires_at
    end

    test "returns error when expires_at equals starts_at", %{contract: contract} do
      same_time = DateTime.utc_now()

      attrs = %{
        starts_at: same_time,
        expires_at: same_time
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(contract.id, attrs)
      assert "must be after starts_at" in errors_on(changeset).expires_at
    end

    test "preserves inserted_at timestamp", %{contract: contract} do
      original_inserted_at = contract.inserted_at

      attrs = %{
        value: Decimal.new("6000.00")
      }

      assert {:ok, %Contract{} = updated_contract} = Update.call(contract.id, attrs)
      assert updated_contract.inserted_at == original_inserted_at
    end

    test "updates multiple times", %{contract: contract} do
      attrs_1 = %{value: Decimal.new("6000.00")}
      assert {:ok, %Contract{} = updated_1} = Update.call(contract.id, attrs_1)
      assert updated_1.value == Decimal.new("6000.00")

      attrs_2 = %{status: "expired"}
      assert {:ok, %Contract{} = updated_2} = Update.call(contract.id, attrs_2)
      assert updated_2.status == "expired"
      assert updated_2.value == Decimal.new("6000.00")

      attrs_3 = %{value: Decimal.new("7000.00")}
      assert {:ok, %Contract{} = updated_3} = Update.call(contract.id, attrs_3)
      assert updated_3.value == Decimal.new("7000.00")
      assert updated_3.status == "expired"
    end
  end
end
