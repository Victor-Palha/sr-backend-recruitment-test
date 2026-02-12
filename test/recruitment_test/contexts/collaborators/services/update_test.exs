defmodule RecruitmentTest.Contexts.Collaborators.Services.UpdateTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Collaborators.Services.Update
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

  describe "call/2" do
    setup do
      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "John Doe",
          email: "john@example.com",
          cpf: "12345678901",
          is_active: false
        })
        |> Repo.insert()

      %{collaborator: collaborator}
    end

    test "updates a collaborator with valid data", %{collaborator: collaborator} do
      attrs = %{
        name: "Jane Doe",
        email: "jane@example.com"
      }

      assert {:ok, %Collaborator{} = updated_collaborator} = Update.call(collaborator.id, attrs)
      assert updated_collaborator.id == collaborator.id
      assert updated_collaborator.name == "Jane Doe"
      assert updated_collaborator.email == "jane@example.com"
      assert updated_collaborator.cpf == "12345678901"
      assert updated_collaborator.is_active == false
    end

    test "updates only name", %{collaborator: collaborator} do
      attrs = %{
        name: "Only Name Changed"
      }

      assert {:ok, %Collaborator{} = updated_collaborator} = Update.call(collaborator.id, attrs)
      assert updated_collaborator.name == "Only Name Changed"
      assert updated_collaborator.email == "john@example.com"
      assert updated_collaborator.is_active == false
    end

    test "updates only email", %{collaborator: collaborator} do
      attrs = %{
        email: "newemail@example.com"
      }

      assert {:ok, %Collaborator{} = updated_collaborator} = Update.call(collaborator.id, attrs)
      assert updated_collaborator.name == "John Doe"
      assert updated_collaborator.email == "newemail@example.com"
      assert updated_collaborator.is_active == false
    end

    test "does not update is_active even if provided", %{collaborator: collaborator} do
      attrs = %{
        name: "Updated Name",
        is_active: true
      }

      assert {:ok, %Collaborator{} = updated_collaborator} = Update.call(collaborator.id, attrs)
      assert updated_collaborator.name == "Updated Name"
      assert updated_collaborator.is_active == false
    end

    test "updates with empty attrs map", %{collaborator: collaborator} do
      attrs = %{}

      assert {:ok, %Collaborator{} = updated_collaborator} = Update.call(collaborator.id, attrs)
      assert updated_collaborator.name == "John Doe"
      assert updated_collaborator.email == "john@example.com"
      assert updated_collaborator.is_active == false
    end

    test "does not update cpf even if provided", %{collaborator: collaborator} do
      attrs = %{
        name: "Updated Name",
        cpf: "99999999999"
      }

      assert {:ok, %Collaborator{} = updated_collaborator} = Update.call(collaborator.id, attrs)
      assert updated_collaborator.name == "Updated Name"
      assert updated_collaborator.cpf == "12345678901"
    end

    test "returns error when collaborator does not exist" do
      non_existent_id = Ecto.UUID.generate()

      attrs = %{
        name: "New Name"
      }

      assert {:error, "Collaborator not found"} = Update.call(non_existent_id, attrs)
    end

    test "returns error with invalid UUID format" do
      attrs = %{
        name: "New Name"
      }

      assert {:error, "Collaborator not found"} = Update.call("invalid-uuid", attrs)
    end

    test "returns error with nil ID" do
      attrs = %{
        name: "New Name"
      }

      assert {:error, "Collaborator not found"} = Update.call(nil, attrs)
    end

    test "returns error with empty string ID" do
      attrs = %{
        name: "New Name"
      }

      assert {:error, "Collaborator not found"} = Update.call("", attrs)
    end

    test "returns error when name is too long", %{collaborator: collaborator} do
      long_name = String.duplicate("a", 251)

      attrs = %{
        name: long_name
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(collaborator.id, attrs)
      assert "should be at most 250 character(s)" in errors_on(changeset).name
    end

    test "returns error when email is invalid", %{collaborator: collaborator} do
      attrs = %{
        email: "invalid-email"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(collaborator.id, attrs)
      assert "must be a valid email" in errors_on(changeset).email
    end

    test "returns error when email is too long", %{collaborator: collaborator} do
      long_email = String.duplicate("a", 242) <> "@test.com"

      attrs = %{
        email: long_email
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(collaborator.id, attrs)
      assert "should be at most 250 character(s)" in errors_on(changeset).email
    end

    test "returns error when email already exists" do
      {:ok, other_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Other User",
          email: "other@example.com",
          cpf: "11111111111",
          is_active: true
        })
        |> Repo.insert()

      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Test User",
          email: "test@example.com",
          cpf: "22222222222",
          is_active: false
        })
        |> Repo.insert()

      attrs = %{
        email: other_collaborator.email
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(collaborator.id, attrs)
      assert "has already been taken" in errors_on(changeset).email
    end

    test "preserves inserted_at timestamp", %{collaborator: collaborator} do
      original_inserted_at = collaborator.inserted_at

      attrs = %{
        name: "Updated Name"
      }

      assert {:ok, %Collaborator{} = updated_collaborator} = Update.call(collaborator.id, attrs)
      assert updated_collaborator.inserted_at == original_inserted_at
    end

    test "updates multiple times", %{collaborator: collaborator} do
      attrs_1 = %{name: "First Update"}
      assert {:ok, %Collaborator{} = updated_1} = Update.call(collaborator.id, attrs_1)
      assert updated_1.name == "First Update"

      attrs_2 = %{email: "second@example.com"}
      assert {:ok, %Collaborator{} = updated_2} = Update.call(collaborator.id, attrs_2)
      assert updated_2.email == "second@example.com"
      assert updated_2.name == "First Update"

      attrs_3 = %{name: "Third Update"}
      assert {:ok, %Collaborator{} = updated_3} = Update.call(collaborator.id, attrs_3)
      assert updated_3.name == "Third Update"
      assert updated_3.email == "second@example.com"
    end
  end
end
