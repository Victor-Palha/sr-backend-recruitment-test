defmodule RecruitmentTest.Repo.Migrations.AddCollaboratorsTable do
  use Ecto.Migration

  def change do
    create table("collaborators") do
      add :name, :string, null: false
      add :email, :string, null: false
      add :cpf, :string, null: false
      add :is_active, :boolean, null: false, default: true

      timestamps()
    end

    create unique_index(:collaborators, [:email])
    create unique_index(:collaborators, [:cpf])
  end
end
