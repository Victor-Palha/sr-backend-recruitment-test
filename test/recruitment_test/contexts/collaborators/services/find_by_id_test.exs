defmodule RecruitmentTest.Contexts.Collaborators.Services.FindByIdTest do
  use RecruitmentTest.DataCase, async: true

  alias RecruitmentTest.Contexts.Collaborators.Services.FindById
  alias RecruitmentTest.Contexts.Collaborators.Collaborator

  describe "call/1" do
    setup do
      {:ok, collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "John Doe",
          email: "john@example.com",
          cpf: "12345678901",
          is_active: true
        })
        |> Repo.insert()

      %{collaborator: collaborator}
    end

    test "finds a collaborator by valid ID", %{collaborator: collaborator} do
      assert {:ok, %Collaborator{} = found_collaborator} = FindById.call(collaborator.id)
      assert found_collaborator.id == collaborator.id
      assert found_collaborator.name == "John Doe"
      assert found_collaborator.email == "john@example.com"
      assert found_collaborator.cpf == "12345678901"
      assert found_collaborator.is_active == true
    end

    test "returns error when collaborator does not exist" do
      non_existent_id = Ecto.UUID.generate()
      assert {:error, "Collaborator not found"} = FindById.call(non_existent_id)
    end

    test "finds inactive collaborator" do
      {:ok, inactive_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Inactive User",
          email: "inactive@example.com",
          cpf: "98765432100",
          is_active: false
        })
        |> Repo.insert()

      assert {:ok, %Collaborator{} = found} = FindById.call(inactive_collaborator.id)
      assert found.is_active == false
    end

    test "finds correct collaborator when multiple exist", %{collaborator: first_collaborator} do
      {:ok, second_collaborator} =
        %Collaborator{}
        |> Collaborator.changeset(%{
          name: "Jane Doe",
          email: "jane@example.com",
          cpf: "11122233344",
          is_active: true
        })
        |> Repo.insert()

      assert {:ok, %Collaborator{} = found_first} = FindById.call(first_collaborator.id)
      assert found_first.id == first_collaborator.id
      assert found_first.name == "John Doe"

      assert {:ok, %Collaborator{} = found_second} = FindById.call(second_collaborator.id)
      assert found_second.id == second_collaborator.id
      assert found_second.name == "Jane Doe"
    end
  end
end
