defmodule PloverWeb.AccountController do
    use PloverWeb, :controller
    plug PloverWeb.Plugs.RequireSiteAuth
    plug PloverWeb.Plugs.RequireAuth when action in [:edit, :update, :delete]

    def index(conn, _params) do
        render conn, "index.html"
    end

    def update(conn, params) do

    end

    def new(conn, params) do

    end

    def edit(conn, params) do

    end

    def delete(conn, params) do

    end

end
