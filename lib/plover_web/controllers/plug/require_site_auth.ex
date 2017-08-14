defmodule PloverWeb.Plugs.RequireSiteAuth do
    @moduledoc """
        Checks to see if the site's password has been provided.
    """
    import Plug.Conn
    import Phoenix.Controller

    alias PloverWeb.Router.Helpers

    def init(_params) do

    end

    def call(conn, _params) do
        if conn.assigns[:sign_in] do
            conn
        else
            conn
            |> put_flash(:error, "You must supply the site's password!")
            |> redirect(to: Helpers.page_path(conn, :index))
            |> halt()
        end
    end

end
