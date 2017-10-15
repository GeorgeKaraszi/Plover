defmodule PloverWeb.PageController do
  use PloverWeb, :controller

  def index(conn, _params) do
    if conn.assigns[:user] do
      redirect(conn, to: account_path(conn, :show))
    else
      render conn, "index.html"
    end
  end

  # Used for waking up free dyno's on heroku using a scheduler
  # Could be used later for re-retrieving data from previous wake states
  def wakeup(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{response: "ok"})
  end
end
