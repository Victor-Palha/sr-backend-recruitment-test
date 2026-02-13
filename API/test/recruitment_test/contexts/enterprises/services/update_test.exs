defmodule RecruitmentTest.Contexts.Enterprises.Services.UpdateTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Enterprises.Services.Update
  alias RecruitmentTest.Contexts.Enterprises.Enterprise

  describe "call/2" do
    setup do
      {:ok, enterprise} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Test Corp",
          commercial_name: "Test Corporation",
          cnpj: "12345678000190",
          description: "Original description"
        })
        |> Repo.insert()

      %{enterprise: enterprise}
    end

    test "updates an enterprise with valid data", %{enterprise: enterprise} do
      attrs = %{
        name: "Updated Corp",
        commercial_name: "Updated Corporation",
        description: "Updated description"
      }

      assert {:ok, %Enterprise{} = updated_enterprise} = Update.call(enterprise.id, attrs)
      assert updated_enterprise.id == enterprise.id
      assert updated_enterprise.name == "Updated Corp"
      assert updated_enterprise.commercial_name == "Updated Corporation"
      assert updated_enterprise.description == "Updated description"
      assert updated_enterprise.cnpj == "12345678000190"
    end

    test "updates only name", %{enterprise: enterprise} do
      attrs = %{
        name: "Only Name Changed"
      }

      assert {:ok, %Enterprise{} = updated_enterprise} = Update.call(enterprise.id, attrs)
      assert updated_enterprise.name == "Only Name Changed"
      assert updated_enterprise.commercial_name == "Test Corporation"
      assert updated_enterprise.description == "Original description"
    end

    test "updates only commercial_name", %{enterprise: enterprise} do
      attrs = %{
        commercial_name: "Only Commercial Name Changed"
      }

      assert {:ok, %Enterprise{} = updated_enterprise} = Update.call(enterprise.id, attrs)
      assert updated_enterprise.name == "Test Corp"
      assert updated_enterprise.commercial_name == "Only Commercial Name Changed"
      assert updated_enterprise.description == "Original description"
    end

    test "updates only description", %{enterprise: enterprise} do
      attrs = %{
        description: "Only description changed"
      }

      assert {:ok, %Enterprise{} = updated_enterprise} = Update.call(enterprise.id, attrs)
      assert updated_enterprise.name == "Test Corp"
      assert updated_enterprise.commercial_name == "Test Corporation"
      assert updated_enterprise.description == "Only description changed"
    end

    test "sets description to nil", %{enterprise: enterprise} do
      attrs = %{
        description: nil
      }

      assert {:ok, %Enterprise{} = updated_enterprise} = Update.call(enterprise.id, attrs)
      assert is_nil(updated_enterprise.description)
    end

    test "updates with empty attrs map", %{enterprise: enterprise} do
      attrs = %{}

      assert {:ok, %Enterprise{} = updated_enterprise} = Update.call(enterprise.id, attrs)
      assert updated_enterprise.name == "Test Corp"
      assert updated_enterprise.commercial_name == "Test Corporation"
      assert updated_enterprise.description == "Original description"
    end

    test "does not update cnpj even if provided", %{enterprise: enterprise} do
      attrs = %{
        name: "Updated Name",
        cnpj: "98765432000100"
      }

      assert {:ok, %Enterprise{} = updated_enterprise} = Update.call(enterprise.id, attrs)
      assert updated_enterprise.name == "Updated Name"
      assert updated_enterprise.cnpj == "12345678000190"
    end

    test "returns error when enterprise does not exist" do
      non_existent_id = Ecto.UUID.generate()

      attrs = %{
        name: "New Name"
      }

      assert {:error, "Enterprise not found"} = Update.call(non_existent_id, attrs)
    end

    test "returns error with invalid UUID format" do
      attrs = %{
        name: "New Name"
      }

      assert {:error, "Enterprise not found"} = Update.call("invalid-uuid", attrs)
    end

    test "returns error with nil ID" do
      attrs = %{
        name: "New Name"
      }

      assert {:error, "Enterprise not found"} = Update.call(nil, attrs)
    end

    test "returns error with empty string ID" do
      attrs = %{
        name: "New Name"
      }

      assert {:error, "Enterprise not found"} = Update.call("", attrs)
    end

    test "returns error when name is blank", %{enterprise: enterprise} do
      attrs = %{
        name: ""
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(enterprise.id, attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error when name is nil", %{enterprise: enterprise} do
      attrs = %{
        name: nil
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(enterprise.id, attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error when commercial_name is blank", %{enterprise: enterprise} do
      attrs = %{
        commercial_name: ""
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(enterprise.id, attrs)
      assert "can't be blank" in errors_on(changeset).commercial_name
    end

    test "returns error when commercial_name is nil", %{enterprise: enterprise} do
      attrs = %{
        commercial_name: nil
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(enterprise.id, attrs)
      assert "can't be blank" in errors_on(changeset).commercial_name
    end

    test "returns error when name exceeds max length", %{enterprise: enterprise} do
      attrs = %{
        name: String.duplicate("a", 251)
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(enterprise.id, attrs)
      assert "should be at most 250 character(s)" in errors_on(changeset).name
    end

    test "returns error when commercial_name exceeds max length", %{enterprise: enterprise} do
      attrs = %{
        commercial_name: String.duplicate("a", 251)
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(enterprise.id, attrs)
      assert "should be at most 250 character(s)" in errors_on(changeset).commercial_name
    end

    test "returns error when description exceeds max length", %{enterprise: enterprise} do
      attrs = %{
        description: String.duplicate("a", 5001)
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(enterprise.id, attrs)
      assert "should be at most 5000 character(s)" in errors_on(changeset).description
    end

    test "updates enterprise with max length values", %{enterprise: enterprise} do
      attrs = %{
        name: String.duplicate("a", 250),
        commercial_name: String.duplicate("b", 250),
        description: String.duplicate("c", 5000)
      }

      assert {:ok, %Enterprise{} = updated_enterprise} = Update.call(enterprise.id, attrs)
      assert String.length(updated_enterprise.name) == 250
      assert String.length(updated_enterprise.commercial_name) == 250
      assert String.length(updated_enterprise.description) == 5000
    end

    test "updates multiple times", %{enterprise: enterprise} do
      attrs_1 = %{name: "First Update"}
      assert {:ok, %Enterprise{} = updated_1} = Update.call(enterprise.id, attrs_1)
      assert updated_1.name == "First Update"

      attrs_2 = %{name: "Second Update"}
      assert {:ok, %Enterprise{} = updated_2} = Update.call(enterprise.id, attrs_2)
      assert updated_2.name == "Second Update"

      attrs_3 = %{commercial_name: "Third Update Commercial"}
      assert {:ok, %Enterprise{} = updated_3} = Update.call(enterprise.id, attrs_3)
      assert updated_3.name == "Second Update"
      assert updated_3.commercial_name == "Third Update Commercial"
    end

    test "different enterprises can be updated independently" do
      {:ok, enterprise_1} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Enterprise One",
          commercial_name: "Enterprise One Corp",
          cnpj: "11111111000111",
          description: "First enterprise"
        })
        |> Repo.insert()

      {:ok, enterprise_2} =
        %Enterprise{}
        |> Enterprise.changeset(%{
          name: "Enterprise Two",
          commercial_name: "Enterprise Two Corp",
          cnpj: "22222222000122",
          description: "Second enterprise"
        })
        |> Repo.insert()

      assert {:ok, updated_1} = Update.call(enterprise_1.id, %{name: "Updated One"})
      assert updated_1.name == "Updated One"

      assert {:ok, updated_2} = Update.call(enterprise_2.id, %{name: "Updated Two"})
      assert updated_2.name == "Updated Two"

      assert updated_1.id != updated_2.id
      assert updated_1.cnpj == "11111111000111"
      assert updated_2.cnpj == "22222222000122"
    end
  end
end
