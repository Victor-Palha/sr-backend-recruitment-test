defmodule RecruitmentTestWeb.Router do
  use RecruitmentTestWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :api

    forward "/graphql", Absinthe.Plug, schema: RecruitmentTestWeb.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: RecruitmentTestWeb.Schema,
      interface: :playground
  end
end
