defmodule PloverWeb.PageControllerTest do
  use PloverWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Login with Githubs"
  end
end
