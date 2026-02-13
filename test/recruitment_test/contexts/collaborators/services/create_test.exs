defmodule RecruitmentTest.Contexts.Collaborators.Services.CreateTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Collaborators.Services.Create
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

  describe "call/1" do
    test "creates a collaborator successfully with valid data" do
      attrs = %{
        name: "John Doe",
        email: "john.doe@example.com",
        cpf: "12345678901"
      }

      assert {:ok, %Collaborator{} = collaborator} = Create.call(attrs)
      assert collaborator.name == "John Doe"
      assert collaborator.email == "john.doe@example.com"
      assert collaborator.cpf == "12345678901"
      assert collaborator.is_active == false
      assert collaborator.id
      assert collaborator.inserted_at
      assert collaborator.updated_at
    end

    test "creates a collaborator with formatted CPF (removes formatting)" do
      attrs = %{
        name: "Jane Doe",
        email: "jane.doe@example.com",
        cpf: "123.456.789-01"
      }

      assert {:ok, %Collaborator{} = collaborator} = Create.call(attrs)
      assert collaborator.cpf == "12345678901"
    end

    test "creates a collaborator with explicit is_active value" do
      attrs = %{
        name: "Active User",
        email: "active@example.com",
        cpf: "98765432100",
        is_active: true
      }

      assert {:ok, %Collaborator{} = collaborator} = Create.call(attrs)
      assert collaborator.is_active == true
    end

    test "returns error when name is missing" do
      attrs = %{
        email: "test@example.com",
        cpf: "12345678901"
      }

      assert {:error, "Invalid attributes. Name, email and CPF are required."} =
               Create.call(attrs)
    end

    test "returns error when email is missing" do
      attrs = %{
        name: "Test User",
        cpf: "12345678901"
      }

      assert {:error, "Invalid attributes. Name, email and CPF are required."} =
               Create.call(attrs)
    end

    test "returns error when email is invalid format" do
      attrs = %{
        name: "Test User",
        email: "invalid-email",
        cpf: "12345678901"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "must be a valid email" in errors_on(changeset).email
    end

    test "returns error when email has spaces" do
      attrs = %{
        name: "Test User",
        email: "test @example.com",
        cpf: "12345678901"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "must be a valid email" in errors_on(changeset).email
    end

    test "returns error when cpf is missing" do
      attrs = %{
        name: "Test User",
        email: "test@example.com"
      }

      assert {:error, "Invalid attributes. Name, email and CPF are required."} =
               Create.call(attrs)
    end

    test "returns error when cpf has incorrect length" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        cpf: "123456789"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "should be 11 character(s)" in errors_on(changeset).cpf
    end

    test "returns error when cpf is too long" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        cpf: "123456789012"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "should be 11 character(s)" in errors_on(changeset).cpf
    end

    test "returns error when name exceeds max length" do
      attrs = %{
        name: String.duplicate("a", 251),
        email: "test@example.com",
        cpf: "12345678901"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "should be at most 250 character(s)" in errors_on(changeset).name
    end

    test "returns error when email exceeds max length" do
      long_email = String.duplicate("a", 240) <> "@example.com"

      attrs = %{
        name: "Test User",
        email: long_email,
        cpf: "12345678901"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
      assert "should be at most 250 character(s)" in errors_on(changeset).email
    end

    test "returns error when trying to create duplicate email" do
      attrs = %{
        name: "First User",
        email: "duplicate@example.com",
        cpf: "12345678901"
      }

      assert {:ok, _collaborator} = Create.call(attrs)

      duplicate_attrs = %{
        name: "Second User",
        email: "duplicate@example.com",
        cpf: "98765432100"
      }

      assert {:error, "A collaborator with this email already exists"} =
               Create.call(duplicate_attrs)
    end

    test "returns error when trying to create duplicate cpf" do
      attrs = %{
        name: "First User",
        email: "first@example.com",
        cpf: "11122233344"
      }

      assert {:ok, _collaborator} = Create.call(attrs)

      duplicate_attrs = %{
        name: "Second User",
        email: "second@example.com",
        cpf: "11122233344"
      }

      assert {:error, "A collaborator with this CPF already exists"} =
               Create.call(duplicate_attrs)
    end

    test "uses default value for is_active when not provided" do
      attrs = %{
        name: "Test User",
        email: "test@example.com",
        cpf: "12345678901"
      }

      assert {:ok, %Collaborator{} = collaborator} = Create.call(attrs)
      assert collaborator.is_active == false
    end

    test "accepts valid email formats" do
      valid_emails = [
        "user@example.com",
        "user.name@example.com",
        "user+tag@example.co.uk",
        "user_name@example-domain.com"
      ]

      Enum.each(valid_emails, fn email ->
        attrs = %{
          name: "Test User",
          email: email,
          cpf: "#{:rand.uniform(89_999_999_999) + 10_000_000_000}",
          is_active: false
        }

        assert {:ok, %Collaborator{}} = Create.call(attrs)
      end)
    end
  end
end
