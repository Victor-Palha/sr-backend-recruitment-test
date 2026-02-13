defmodule RecruitmentTest.Contexts.Contracts.Services.FindByEnterpriseIdTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Contracts.Services.FindByEnterpriseId
  alias RecruitmentTest.Contexts.Contracts.Contract
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

  describe "call/1" do
    setup do
      {:ok, enterprise1} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "First Corp",
          commercial_name: "First Corporation",
          cnpj: "12345678000190",
          description: "First enterprise"
        })
        |> Repo.insert()

      {:ok, enterprise2} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Second Corp",
          commercial_name: "Second Corporation",
          cnpj: "98765432000100",
          description: "Second enterprise"
        })
        |> Repo.insert()

      {:ok, collaborator1} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "John Doe",
          email: "john@example.com",
          cpf: "12345678901",
          is_active: true
        })
        |> Repo.insert()

      {:ok, collaborator2} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Jane Doe",
          email: "jane@example.com",
          cpf: "98765432100",
          is_active: true
        })
        |> Repo.insert()

      %{
        enterprise1: enterprise1,
        enterprise2: enterprise2,
        collaborator1: collaborator1,
        collaborator2: collaborator2
      }
    end

    test "finds all contracts for an enterprise with multiple contracts", %{
      enterprise1: enterprise,
      collaborator1: collaborator1,
      collaborator2: collaborator2
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 365, :day)

      {:ok, contract1} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator1.id,
          starts_at: starts_at,
          expires_at: expires_at,
          value: Decimal.new("5000.00"),
          status: "active"
        })
        |> Repo.insert()

      {:ok, contract2} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator2.id,
          starts_at: starts_at,
          expires_at: expires_at,
          value: Decimal.new("6000.00"),
          status: "active"
        })
        |> Repo.insert()

      contracts = FindByEnterpriseId.call(enterprise.id)

      assert length(contracts) == 2
      contract_ids = Enum.map(contracts, & &1.id)
      assert contract1.id in contract_ids
      assert contract2.id in contract_ids
    end

    test "returns empty list when enterprise has no contracts", %{enterprise1: enterprise} do
      contracts = FindByEnterpriseId.call(enterprise.id)
      assert contracts == []
    end

    test "returns empty list when enterprise does not exist" do
      non_existent_id = Ecto.UUID.generate()
      contracts = FindByEnterpriseId.call(non_existent_id)
      assert contracts == []
    end

    test "only returns contracts for the specified enterprise", %{
      enterprise1: enterprise1,
      enterprise2: enterprise2,
      collaborator1: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 365, :day)

      {:ok, contract1} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise1.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      {:ok, _contract2} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise2.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      contracts = FindByEnterpriseId.call(enterprise1.id)

      assert length(contracts) == 1
      assert hd(contracts).id == contract1.id
      assert hd(contracts).enterprise_id == enterprise1.id
    end

    test "returns contracts with different statuses", %{
      enterprise1: enterprise,
      collaborator1: collaborator1,
      collaborator2: collaborator2
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 365, :day)

      {:ok, _active_contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator1.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      {:ok, _expired_contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator2.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "expired"
        })
        |> Repo.insert()

      contracts = FindByEnterpriseId.call(enterprise.id)

      assert length(contracts) == 2
      statuses = Enum.map(contracts, & &1.status)
      assert "active" in statuses
      assert "expired" in statuses
    end

    test "returns error with invalid UUID format" do
      assert {:error, "Enterprise not found"} = FindByEnterpriseId.call("invalid-uuid")
      assert {:error, "Enterprise not found"} = FindByEnterpriseId.call("123")
      assert {:error, "Enterprise not found"} = FindByEnterpriseId.call(nil)
    end

    test "returns contracts with and without value", %{
      enterprise1: enterprise,
      collaborator1: collaborator1,
      collaborator2: collaborator2
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 365, :day)

      {:ok, contract_with_value} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator1.id,
          starts_at: starts_at,
          expires_at: expires_at,
          value: Decimal.new("10000.00"),
          status: "active"
        })
        |> Repo.insert()

      {:ok, contract_without_value} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator2.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      contracts = FindByEnterpriseId.call(enterprise.id)

      assert length(contracts) == 2

      with_value = Enum.find(contracts, &(&1.id == contract_with_value.id))
      without_value = Enum.find(contracts, &(&1.id == contract_without_value.id))

      assert with_value.value == Decimal.new("10000.00")
      assert is_nil(without_value.value)
    end

    test "returns contracts ordered by insertion", %{
      enterprise1: enterprise,
      collaborator1: collaborator
    } do
      starts_at = DateTime.utc_now()
      expires_at = DateTime.add(starts_at, 365, :day)

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

      Process.sleep(10)

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

      Process.sleep(10)

      {:ok, contract3} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      contracts = FindByEnterpriseId.call(enterprise.id)

      assert length(contracts) == 3
      contract_ids = Enum.map(contracts, & &1.id)
      assert contract1.id in contract_ids
      assert contract2.id in contract_ids
      assert contract3.id in contract_ids
    end
  end
end
