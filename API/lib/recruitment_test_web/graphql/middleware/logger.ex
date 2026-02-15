defmodule RecruitmentTestWeb.Graphql.Middleware.Logger do
  @moduledoc """
  Absinthe middleware that logs GraphQL query and mutation execution.

  Automatically inherits `request_id` from the process Logger metadata,
  ensuring all GraphQL logs are correlated with the originating HTTP request.
  """
  @behaviour Absinthe.Middleware

  require Logger

  @impl true
  def call(%{state: :resolved} = resolution, {:after, start_time, field_name, parent_type}) do
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :microsecond) / 1000

    case resolution.errors do
      [] ->
        Logger.info("GraphQL operation completed",
          graphql_field: field_name,
          graphql_parent_type: parent_type,
          duration_ms: Float.round(duration_ms, 2)
        )

      errors ->
        Logger.warning("GraphQL operation failed",
          graphql_field: field_name,
          graphql_parent_type: parent_type,
          duration_ms: Float.round(duration_ms, 2),
          errors: inspect(errors)
        )
    end

    resolution
  end

  def call(resolution, {:after, _start_time, _field_name, _parent_type}) do
    resolution
  end

  def call(resolution, _config) do
    start_time = System.monotonic_time()
    field_name = resolution.definition.name
    parent_type = resolution.parent_type.identifier

    Logger.info("GraphQL operation started",
      graphql_field: field_name,
      graphql_parent_type: parent_type
    )

    %{
      resolution
      | middleware:
          resolution.middleware ++
            [{__MODULE__, {:after, start_time, field_name, parent_type}}]
    }
  end
end
