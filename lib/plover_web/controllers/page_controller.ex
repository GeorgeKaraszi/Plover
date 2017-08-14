defmodule PloverWeb.PageController do
  use PloverWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def signin(conn, %{"password" => %{"password" => password}}) do
    if password == System.get_env("SITE_PASSWORD") do
      conn
      |> put_session(:site_login, true)
      |> put_flash(:info, "success")
      |> redirect(to: account_path(conn, :index, thread))
    else
      conn
      |> put_flash(:error, "Wrong Password!")
      |> render("index.html")
    end
  end
end
