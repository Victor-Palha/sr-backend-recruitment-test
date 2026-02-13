defmodule RecruitmentTestWeb.Graphql.Types.Pagination do
  use Absinthe.Schema.Notation

  @desc "Page information"
  object :page_info do
    field(:has_next_page, non_null(:boolean))
    field(:has_previous_page, non_null(:boolean))
    field(:start_cursor, :string)
    field(:end_cursor, :string)
    field(:total_count, non_null(:integer))
  end

  @desc "Pagination input"
  input_object :pagination_input do
    field(:page, :integer, default_value: 1)
    field(:page_size, :integer, default_value: 10)
  end
end
