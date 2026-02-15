defmodule RecruitmentTest.Contexts.Collaborators.Services.Create do
  @moduledoc """
  Service module responsible for creating a new collaborator.
  The collaborator's is created with is_active set to false by default.
  """
  alias RecruitmentTest.Contexts.Collaborators.Collaborator
  alias RecruitmentTest.Repo

  require Logger

  @spec call(
          attrs :: %{
            name: String.t(),
            email: String.t(),
            cpf: String.t()
          }
        ) :: {:ok, map()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def call(%{name: _name, email: email, cpf: cpf} = attrs) do
    Logger.info("Creating collaborator", service: "collaborators.create", email: email)

    with {:ok, _} <- collaborator_with_same_email_exists?(email),
         {:ok, _} <- collaborator_with_same_cpf_exists?(cpf) do
      case create_collaborator(attrs) do
        {:ok, collaborator} ->
          Logger.info("Collaborator created successfully",
            service: "collaborators.create",
            collaborator_id: collaborator.id
          )

          {:ok, collaborator}

        {:error, changeset} ->
          Logger.warning("Collaborator creation failed - validation error",
            service: "collaborators.create",
            errors: inspect(changeset.errors)
          )

          {:error, changeset}
      end
    else
      {:error, reason} ->
        Logger.warning("Collaborator creation failed",
          service: "collaborators.create",
          reason: reason
        )

        {:error, reason}
    end
  end

  def call(_attrs) do
    Logger.warning("Collaborator creation failed - invalid attributes",
      service: "collaborators.create"
    )

    {:error, "Invalid attributes. Name, email and CPF are required."}
  end

  defp collaborator_with_same_email_exists?(email) do
    RecruitmentTest.Contexts.Collaborators.Services.FindByEmail.call(email)
    |> case do
      {:ok, _collaborator} -> {:error, "A collaborator with this email already exists"}
      {:error, _reason} -> {:ok, false}
    end
  end

  defp collaborator_with_same_cpf_exists?(cpf) do
    RecruitmentTest.Contexts.Collaborators.Services.FindByCpf.call(cpf)
    |> case do
      {:ok, _collaborator} -> {:error, "A collaborator with this CPF already exists"}
      {:error, _reason} -> {:ok, false}
    end
  end

  defp create_collaborator(attrs) do
    %Collaborator{}
    |> Collaborator.changeset(attrs)
    |> Repo.insert()
  end
end
