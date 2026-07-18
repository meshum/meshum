defmodule MeshumWeb.Router do
  @moduledoc """
  Routes for the control plane web interface.
  """
  use MeshumWeb, :router

  import MeshumWeb.Plugs.Auth, only: [requires_user: 2, fetch_current_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_current_user
    plug :put_root_layout, html: {MeshumWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MeshumWeb.Plugs.Csp
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/auth", MeshumWeb.Controllers.Auth do
    pipe_through :browser

    get "/login", AuthController, :login_page
    get "/login/:provider", AuthController, :login
    get "/callback/:provider", AuthController, :callback
    get "/logout", AuthController, :logout
  end

  scope "/", MeshumWeb do
    pipe_through [:browser, :requires_user]

    get "/", PageController, :home

    # Nav sections whose screens aren't built yet render a stub through the
    # shell (see PageController.section/2 and docs/control-plane.md#navigation).
    get "/policies", PageController, :section
    get "/skills", PageController, :section
    get "/upstream", PageController, :section
    get "/machines", PageController, :section
    get "/telemetry", PageController, :section
    get "/settings", PageController, :section
  end

  scope "/oauth", MeshumWeb.Controllers.Oauth do
    pipe_through :api

    post "/revoke", RevokeController, :revoke
    post "/token", TokenController, :token
    post "/introspect", IntrospectController, :introspect
  end

  scope "/openid", MeshumWeb.Controllers.Openid do
    pipe_through [:api]

    get "/userinfo", UserinfoController, :userinfo
    post "/userinfo", UserinfoController, :userinfo
    get "/jwks", JwksController, :jwks_index
  end

  scope "/openid", MeshumWeb.Controllers.Openid do
    pipe_through [:browser, :fetch_current_user]

    get "/authorize", AuthorizeController, :authorize
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:meshum_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MeshumWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
