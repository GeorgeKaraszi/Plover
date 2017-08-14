defmodule PloverWeb.PageController do
  use PloverWeb, :controller

  def index(conn, _params) do
    if conn.assigns[:user] do
      redirect(conn, to: account_path(conn, :show))
    else
      render conn, "index.html"
    end
  end
end
