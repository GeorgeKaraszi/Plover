defmodule PloverWeb.PageControllerTest do
  use PloverWeb.ConnCase

  alias Github.Worker

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Login with Githubs"
  end

  test "GET /wakeup", %{conn: conn} do
    pull_url     = "http://google.com"
    process_name = String.to_atom(pull_url)
    github_state =
      :github_state
      |> build(pull_request_url: pull_url)
      |> assign_reviewers()
      |> assign_owner()
      |> Redis.submit(pull_url)

    assert Process.whereis(process_name) == nil

    conn = get conn, "/wakeup"
    assert text_response(conn, 200) =~ "ok"

    pid = Process.whereis(process_name)
    assert pid != nil

    {:ok, process_state} = Worker.fetch_state(pid)
    assert Map.equal?(process_state, github_state) == true
  end
end
