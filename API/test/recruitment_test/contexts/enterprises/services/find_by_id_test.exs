defmodule RecruitmentTest.Contexts.Enterprises.Services.FindByIdTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Enterprises.Services.FindById
  alias RecruitmentTest.Contexts.Enterprises.Enterprise

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

      %{enterprise: enterprise}
    end

    test "finds an enterprise by valid ID", %{enterprise: enterprise} do
      assert {:ok, %Enterprise{} = found_enterprise} = FindById.call(enterprise.id)
      assert found_enterprise.id == enterprise.id
      assert found_enterprise.name == "Test Corp"
      assert found_enterprise.commercial_name == "Test Corporation"
      assert found_enterprise.cnpj == "12345678000190"
      assert found_enterprise.description == "Test enterprise"
    end

    test "returns error when enterprise does not exist" do
      non_existent_id = Ecto.UUID.generate()
      assert {:error, "Enterprise not found"} = FindById.call(non_existent_id)
    end

    test "returns error with invalid UUID format" do
      assert {:error, "Enterprise not found"} = FindById.call("invalid-uuid")
    end

    test "returns error with nil ID" do
      assert {:error, "Enterprise not found"} = FindById.call(nil)
    end

    test "returns error with empty string ID" do
      assert {:error, "Enterprise not found"} = FindById.call("")
    end

    test "finds enterprise with nil description" do
      {:ok, enterprise_without_desc} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Another Corp",
          commercial_name: "Another Corporation",
          cnpj: "98765432000100",
          description: nil
        })
        |> Repo.insert()

      assert {:ok, %Enterprise{} = found} = FindById.call(enterprise_without_desc.id)
      assert is_nil(found.description)
    end

    test "finds correct enterprise when multiple exist", %{enterprise: first_enterprise} do
      {:ok, second_enterprise} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Second Corp",
          commercial_name: "Second Corporation",
          cnpj: "11122233300044",
          description: "Second enterprise"
        })
        |> Repo.insert()

      assert {:ok, %Enterprise{} = found_first} = FindById.call(first_enterprise.id)
      assert found_first.id == first_enterprise.id
      assert found_first.name == "Test Corp"

      assert {:ok, %Enterprise{} = found_second} = FindById.call(second_enterprise.id)
      assert found_second.id == second_enterprise.id
      assert found_second.name == "Second Corp"
    end
  end
end
