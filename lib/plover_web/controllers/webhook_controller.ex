defmodule PloverWeb.WebhookController do
  use PloverWeb, :controller

  alias Plover.Github

  def payload(conn, %{"payload" => payload}) do
    payload = Poison.decode!(payload)

    case payload["action"] do
      "review_requested" ->
        Github.assign_pull_request(payload)
      "review_request_removed" ->
        Github.assign_pull_request(payload)
      _ ->
        IO.puts "unknown action"
    end

    conn
    |> put_status(:ok)
    |> json(%{reponse: :ok})
  end
end
