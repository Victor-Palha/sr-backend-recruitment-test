defmodule RecruitmentTest.Contexts.Contracts.Contract do
  use RecruitmentTest.Schema

  import Ecto.Changeset

  @valid_statuses ~w(active expired cancelled)

  schema "contracts" do
    field :value, :decimal
    field :starts_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :status, :string, default: "active"

    belongs_to :enterprise, RecruitmentTest.Contexts.Enterprises.Enterprise
    belongs_to :collaborator, RecruitmentTest.Contexts.Collaborators.Collaborator

    timestamps()
  end

  @doc false
  def changeset(contract, attrs) do
    contract
    |> cast(attrs, [
      :enterprise_id,
      :collaborator_id,
      :value,
      :starts_at,
      :expires_at,
      :status
    ])
    |> validate_required([:enterprise_id, :collaborator_id, :starts_at, :expires_at, :status])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_dates()
    |> foreign_key_constraint(:enterprise_id)
    |> foreign_key_constraint(:collaborator_id)
  end

  defp validate_dates(changeset) do
    starts_at = get_field(changeset, :starts_at)
    expires_at = get_field(changeset, :expires_at)

    case {starts_at, expires_at} do
      {%DateTime{} = starts, %DateTime{} = expires} ->
        if DateTime.compare(expires, starts) == :gt do
          changeset
        else
          add_error(changeset, :expires_at, "must be after starts_at")
        end

      _ ->
        changeset
    end
  end

  def update_changeset(contract, attrs) do
    contract
    |> cast(attrs, [:value, :starts_at, :expires_at, :status])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_dates()
  end
end
