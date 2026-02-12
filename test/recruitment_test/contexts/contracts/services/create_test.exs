defmodule RecruitmentTest.Contexts.Contracts.Services.CreateTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Contracts.Services.Create
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

      %{enterprise: enterprise, collaborator: collaborator}
    end

    test "creates a contract successfully with valid data", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 365, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        value: Decimal.new("5000.00"),
        status: "active"
      }

      assert {:ok, %Contract{} = contract} = Create.call(attrs)
      assert contract.enterprise_id == enterprise.id
      assert contract.collaborator_id == collaborator.id
      assert contract.value == Decimal.new("5000.00")
      assert contract.status == "active"
      assert contract.id
      assert contract.inserted_at
      assert contract.updated_at

      updated_collaborator = Repo.get!(Collaborator, collaborator.id)
      assert updated_collaborator.is_active == true
    end

    test "creates a contract without value", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:ok, %Contract{} = contract} = Create.call(attrs)
      assert is_nil(contract.value)
    end

    test "creates a contract with default status", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at
      }

      assert {:ok, %Contract{} = contract} = Create.call(attrs)
      assert contract.status == "active"
    end

    test "creates a contract with expired status", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 1, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "expired"
      }

      assert {:ok, %Contract{} = contract} = Create.call(attrs)
      assert contract.status == "expired"
    end

    test "creates a contract with cancelled status", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 1, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "cancelled"
      }

      assert {:ok, %Contract{} = contract} = Create.call(attrs)
      assert contract.status == "cancelled"
    end

    test "returns error when enterprise does not exist", %{collaborator: collaborator} do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs = %{
        enterprise_id: Ecto.UUID.generate(),
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:error, "Enterprise not found"} = Create.call(attrs)
    end

    test "returns error when collaborator does not exist", %{enterprise: enterprise} do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: Ecto.UUID.generate(),
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:error, "Collaborator not found"} = Create.call(attrs)
    end

    test "returns error when expires_at is before starts_at", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, -1, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "must be after starts_at" in errors_on(changeset).expires_at
    end

    test "returns error when expires_at equals starts_at", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = starts_at

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "must be after starts_at" in errors_on(changeset).expires_at
    end

    test "returns error when enterprise_id is missing", %{collaborator: collaborator} do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs = %{
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:error, "Enterprise not found"} = Create.call(attrs)
    end

    test "returns error when collaborator_id is missing", %{enterprise: enterprise} do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:error, "Collaborator not found"} = Create.call(attrs)
    end

    test "returns error when starts_at is missing", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      expires_at = DateTime.utc_now()

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        expires_at: expires_at,
        status: "active"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "can't be blank" in errors_on(changeset).starts_at
    end

    test "returns error when expires_at is missing", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        status: "active"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "can't be blank" in errors_on(changeset).expires_at
    end

    test "returns error when status is invalid", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "invalid_status"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "creates multiple contracts for same collaborator", %{
      enterprise: enterprise,
      collaborator: collaborator
    } do
      # First contract
      starts_at_1 = DateTime.utc_now()
      expires_at_1 = DateTime.add(starts_at_1, 30, :day)

      attrs_1 = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at_1,
        expires_at: expires_at_1,
        value: Decimal.new("3000.00"),
        status: "active"
      }

      assert {:ok, %Contract{} = contract_1} = Create.call(attrs_1)

      starts_at_2 = DateTime.add(expires_at_1, 1, :day)
      expires_at_2 = DateTime.add(starts_at_2, 30, :day)

      attrs_2 = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator.id,
        starts_at: starts_at_2,
        expires_at: expires_at_2,
        value: Decimal.new("4000.00"),
        status: "active"
      }

      assert {:ok, %Contract{} = contract_2} = Create.call(attrs_2)
      assert contract_1.id != contract_2.id
    end

    test "creates multiple contracts for same enterprise with different collaborators", %{
      enterprise: enterprise
    } do
      {:ok, collaborator_1} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Jane Doe",
          email: "jane@example.com",
          cpf: "98765432100",
          is_active: true
        })
        |> Repo.insert()

      {:ok, collaborator_2} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Bob Smith",
          email: "bob@example.com",
          cpf: "11122233344",
          is_active: true
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs_1 = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator_1.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      attrs_2 = %{
        enterprise_id: enterprise.id,
        collaborator_id: collaborator_2.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:ok, %Contract{} = contract_1} = Create.call(attrs_1)
      assert {:ok, %Contract{} = contract_2} = Create.call(attrs_2)
      assert contract_1.id != contract_2.id
      assert contract_1.collaborator_id != contract_2.collaborator_id
    end

    test "activates inactive collaborator when contract is created", %{enterprise: enterprise} do
      {:ok, inactive_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Inactive User",
          email: "inactive@example.com",
          cpf: "55566677788",
          is_active: false
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: inactive_collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:ok, %Contract{}} = Create.call(attrs)

      updated_collaborator = Repo.get!(Collaborator, inactive_collaborator.id)
      assert updated_collaborator.is_active == true
    end

    test "keeps collaborator active when already active", %{enterprise: enterprise} do
      {:ok, active_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Active User",
          email: "alreadyactive@example.com",
          cpf: "99988877766",
          is_active: true
        })
        |> Repo.insert()

      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 30, :day)

      attrs = %{
        enterprise_id: enterprise.id,
        collaborator_id: active_collaborator.id,
        starts_at: starts_at,
        expires_at: expires_at,
        status: "active"
      }

      assert {:ok, %Contract{}} = Create.call(attrs)

      updated_collaborator = Repo.get!(Collaborator, active_collaborator.id)
      assert updated_collaborator.is_active == true
    end
  end
end
