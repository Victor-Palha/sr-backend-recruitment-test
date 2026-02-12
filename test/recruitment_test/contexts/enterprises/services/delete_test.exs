defmodule RecruitmentTest.Contexts.Enterprises.Services.DeleteTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Enterprises.Services.Delete
  alias RecruitmentTest.Contexts.Enterprises.Enterprise
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Contexts.Contracts.Contract

  describe "call/1" do
    test "deletes an enterprise successfully" do
      {:ok, enterprise} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Test Corp",
          commercial_name: "Test Corporation",
          cnpj: "12345678000190",
          description: "Test enterprise to be deleted"
        })
        |> Repo.insert()

      assert {:ok, deleted_enterprise} = Delete.call(enterprise.id)
      assert deleted_enterprise.id == enterprise.id
      assert deleted_enterprise.name == "Test Corp"

      assert Repo.get(Enterprise, enterprise.id) == nil
    end

    test "returns error when enterprise does not exist" do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, "Enterprise not found"} = Delete.call(non_existent_id)
    end

    test "returns error when enterprise has related contracts" do
      {:ok, enterprise} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Enterprise with Contracts",
          commercial_name: "Enterprise Corporation",
          cnpj: "98765432000100",
          description: "Enterprise with contracts"
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

      {:ok, _contract} =
        %Contract{}
        |> Contract.changeset(%{
          enterprise_id: enterprise.id,
          collaborator_id: collaborator.id,
          starts_at: starts_at,
          expires_at: expires_at,
          status: "active"
        })
        |> Repo.insert()

      assert {:error, "Cannot delete enterprise with existing contracts"} =
               Delete.call(enterprise.id)

      # Verify enterprise was not deleted
      assert Repo.get(Enterprise, enterprise.id) != nil
    end

    test "deletes multiple enterprises independently" do
      {:ok, enterprise1} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "First Corp",
          commercial_name: "First Corporation",
          cnpj: "11111111000111",
          description: "First enterprise"
        })
        |> Repo.insert()

      {:ok, enterprise2} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Second Corp",
          commercial_name: "Second Corporation",
          cnpj: "22222222000122",
          description: "Second enterprise"
        })
        |> Repo.insert()

      assert {:ok, _deleted1} = Delete.call(enterprise1.id)
      assert {:ok, _deleted2} = Delete.call(enterprise2.id)

      assert Repo.get(Enterprise, enterprise1.id) == nil
      assert Repo.get(Enterprise, enterprise2.id) == nil
    end

    test "returns error when trying to delete already deleted enterprise" do
      {:ok, enterprise} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Temporary Corp",
          commercial_name: "Temporary Corporation",
          cnpj: "33333333000133",
          description: "Temporary enterprise"
        })
        |> Repo.insert()

      assert {:ok, _deleted} = Delete.call(enterprise.id)

      assert {:error, "Enterprise not found"} = Delete.call(enterprise.id)
    end

    test "returns error with nil id" do
      assert {:error, "Enterprise not found"} = Delete.call(nil)
    end

    test "deletes enterprise without description" do
      {:ok, enterprise} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Minimal Corp",
          commercial_name: "Minimal Corporation",
          cnpj: "44444444000144",
          description: nil
        })
        |> Repo.insert()

      assert {:ok, deleted_enterprise} = Delete.call(enterprise.id)
      assert is_nil(deleted_enterprise.description)
      assert Repo.get(Enterprise, enterprise.id) == nil
    end
  end
end
