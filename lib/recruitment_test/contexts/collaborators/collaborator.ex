defmodule RecruitmentTest.Contexts.Collaborators.Collaborator do
  use RecruitmentTest.Schema

  import Ecto.Changeset

  schema "collaborators" do
    field :name, :string
    field :email, :string
    field :cpf, :string
    field :is_active, :boolean, default: true

    has_many :contracts, RecruitmentTest.Contexts.Contracts.Contract,
      foreign_key: :collaborator_id

    has_many :tasks, RecruitmentTest.Contexts.Tasks.Task, foreign_key: :collaborator_id
    has_many :reports, RecruitmentTest.Contexts.Reports.Report, foreign_key: :collaborator_id

    timestamps()
  end

  @doc false
  def changeset(collaborator, attrs) do
    collaborator
    |> cast(attrs, [
      :name,
      :email,
      :cpf,
      :is_active
    ])
    |> handle_name()
    |> handle_email()
    |> handle_cpf()
    |> handle_is_active()
  end

  defp handle_name(changeset) do
    changeset
    |> validate_required(:name)
    |> validate_length(:name, max: 250)
  end

  defp handle_email(changeset) do
    changeset
    |> validate_required(:email)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 250)
    |> unique_constraint(:email)
  end

  defp handle_cpf(changeset) do
    changeset
    |> validate_required(:cpf)
    |> update_change(:cpf, &numbers_only/1)
    |> validate_length(:cpf, is: 11)
    |> unique_constraint(:cpf)
  end

  defp handle_is_active(changeset) do
    changeset
    |> validate_required(:is_active)
  end

  defp numbers_only(value) do
    String.replace(value, ~r/[^\d]/, "")
  end
end
