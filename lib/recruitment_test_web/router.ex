defmodule RecruitmentTestWeb.Router do
  use RecruitmentTestWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug :accepts, ["json"]
    plug RecruitmentTestWeb.Plugs.GraphQLContext
  end

  pipeline :authenticated do
    plug RecruitmentTestWeb.Plugs.Authenticate
  end

  # Public authentication endpoints
  scope "/api", RecruitmentTestWeb do
    pipe_through :api

    post "/auth/login", AuthController, :authenticate
    post "/auth/refresh", AuthController, :refresh
    post "/auth/logout", AuthController, :logout
  end

  # Protected endpoints (require authentication)
  scope "/api", RecruitmentTestWeb do
    pipe_through [:api, :authenticated]

    post "/users", UserController, :create
  end

  # GraphQL endpoints
  scope "/" do
    pipe_through :graphql

    forward "/graphql", Absinthe.Plug, schema: RecruitmentTestWeb.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: RecruitmentTestWeb.Schema,
      interface: :playground
  end

  if Application.compile_env(:recruitment_test, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: RecruitmentTestWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
