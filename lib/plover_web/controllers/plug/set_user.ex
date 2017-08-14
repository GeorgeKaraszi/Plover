defmodule PloverWeb.Plugs.SetUser do
    @moduledoc """
        Once the user has signin, assign the user object to the connection.
        Otherwise set it to nil if no user is signed in.
    """
    import Plug.Conn

    alias Plover.Account.User

    def init(_params) do
    end

    # Assigns the user object to connection if the user has signed in
    def call(conn, _params) do
        user_id = fetch_user_id(conn)
        user    = if user_id, do: User.find(user_id), else: nil
        assign(conn, :user, user)
    end

    defp fetch_user_id(conn) do
        if Mix.env == :test do
            conn.cookies["user_id"]
        else
            get_session(conn, :user_id)
        end
    end
end
