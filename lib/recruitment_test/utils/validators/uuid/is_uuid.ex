defmodule RecruitmentTest.Utils.Validators.Uuid.IsUuid do
  @moduledoc """
  This module defines a guard to validate if a given value is a valid UUID string.
  Note: I would probably use a `Ecto.UUID` for more robust validation in a real application, but this guard provides a simple check for the UUID format
  and is more performant for basic checks.
  """
  defguard is_uuid(value)
           when is_binary(value) and
                  byte_size(value) == 36 and
                  binary_part(value, 8, 1) == "-" and
                  binary_part(value, 13, 1) == "-" and
                  binary_part(value, 18, 1) == "-" and
                  binary_part(value, 23, 1) == "-"
end
