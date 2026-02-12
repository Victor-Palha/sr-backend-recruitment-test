defmodule RecruitmentTest.Contexts.Enterprises.Services.CreateTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Enterprises.Services.Create
  alias RecruitmentTest.Contexts.Enterprises.Enterprise

  describe "call/1" do
    test "creates an enterprise successfully with valid CNPJ" do
      attrs = %{
        cnpj: "12345678000190",
        description: "Test enterprise description"
      }

      assert {:ok, %Enterprise{} = enterprise} = Create.call(attrs)
      assert enterprise.cnpj == "12345678000190"
      assert enterprise.name == "Teste Corp"
      assert enterprise.commercial_name == "EMPRESA TESTE LTDA"
      assert enterprise.description == "Test enterprise description"
      assert enterprise.id
      assert enterprise.inserted_at
      assert enterprise.updated_at
    end

    test "creates an enterprise with formatted CNPJ (removes formatting)" do
      attrs = %{
        cnpj: "12.345.678/0001-90",
        description: nil
      }

      assert {:ok, %Enterprise{} = enterprise} = Create.call(attrs)
      assert enterprise.cnpj == "12345678000190"
    end

    test "creates an enterprise without description" do
      attrs = %{
        cnpj: "98765432000100",
        description: nil
      }

      assert {:ok, %Enterprise{} = enterprise} = Create.call(attrs)
      assert enterprise.cnpj == "98765432000100"
      assert is_nil(enterprise.description)
    end

    test "returns error when CNPJ is invalid (mock validator returns error)" do
      attrs = %{
        cnpj: "00000000000000",
        description: "Test"
      }

      assert {:error, reason} = Create.call(attrs)
      assert reason == "Invalid CNPJ: CNPJ inválido"
    end

    test "returns error when CNPJ is another invalid pattern" do
      attrs = %{
        cnpj: "11111111111111",
        description: "Test"
      }

      assert {:error, reason} = Create.call(attrs)
      assert reason == "Invalid CNPJ: CNPJ inválido"
    end

    test "returns error when trying to create duplicate CNPJ" do
      attrs = %{
        cnpj: "12345678000190",
        description: "First enterprise"
      }

      assert {:ok, _enterprise} = Create.call(attrs)

      duplicate_attrs = %{
        cnpj: "12345678000190",
        description: "Duplicate enterprise"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(duplicate_attrs)
      assert "has already been taken" in errors_on(changeset).cnpj
    end

    test "returns changeset error when data is invalid" do
      attrs = %{
        cnpj: "12345678000190",
        description: String.duplicate("a", 6000)
      }

      assert {:error, _enterprise} = Create.call(attrs)
    end

    test "merges CNPJ validator data with provided attributes" do
      attrs = %{
        cnpj: "55555555000155",
        description: "Custom description"
      }

      assert {:ok, %Enterprise{} = enterprise} = Create.call(attrs)
      assert enterprise.name == "Teste Corp"
      assert enterprise.commercial_name == "EMPRESA TESTE LTDA"
      assert enterprise.description == "Custom description"
      assert enterprise.cnpj == "55555555000155"
    end
  end
end
