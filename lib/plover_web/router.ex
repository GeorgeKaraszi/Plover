defmodule PloverWeb.Router do
  use PloverWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PloverWeb.Plugs.SetUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PloverWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/account", AccountController, except: [:new], singleton: true

    get "/wakeup", PageController, :wakeup
  end

  scope "/auth", PloverWeb do
    pipe_through :browser

    get "/signout", AuthController, :signout
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/github", PloverWeb do
    pipe_through :api

    post "/webhook", WebhookController, :payload
  end

  # Other scopes may use custom stacks.
  # scope "/api", PloverWeb do
  #   pipe_through :api
  # end
end
