defmodule RecruitmentTestWeb.Graphql.Types.User do
  use Absinthe.Schema.Notation

  @desc "Paginated users result"
  object :paginated_users do
    field(:data, non_null(list_of(non_null(:user))))
    field(:page_info, non_null(:page_info))
  end

  @desc "user role enum"
  enum :user_role do
    value(:admin, as: "admin", description: "Administrator user")
    value(:user, as: "user", description: "Regular user")
  end

  @desc "A user of the system"
  object :user do
    field(:id, non_null(:id), description: "The unique identifier of the user")
    field(:name, non_null(:string), description: "The full name of the user")
    field(:email, non_null(:string), description: "The email address of the user")
    field(:role, non_null(:user_role), description: "The role of the user in the system")
    field(:is_active, non_null(:boolean), description: "Whether the user is active")
    field(:inserted_at, non_null(:naive_datetime), description: "When the user was created")
    field(:updated_at, non_null(:naive_datetime), description: "When the user was last updated")
  end

  @desc "User filters"
  input_object :user_filters do
    field(:name, :string)
    field(:email, :string)
    field(:role, :user_role)
    field(:is_active, :boolean)
  end
end
