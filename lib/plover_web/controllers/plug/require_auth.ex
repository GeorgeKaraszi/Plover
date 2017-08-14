defmodule PloverWeb.Plugs.RequireAuth do
    @moduledoc """
        Checks to see if the user has been assigned to the connection.
        If not, it will redirect back to the root page with an error message.
    """
    import Plug.Conn
    import Phoenix.Controller

    alias PloverWeb.Router.Helpers

    def init(_params) do

    end

    def call(conn, _params) do
        if conn.assigns[:user] do
            conn
        else
            conn
            |> put_flash(:error, "You must sign into your github account!")
            |> redirect(to: Helpers.account_path(conn, :index))
            |> halt()
        end
    end

end
