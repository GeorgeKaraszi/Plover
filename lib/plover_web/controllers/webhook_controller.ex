defmodule PloverWeb.WebhookController do
  use PloverWeb, :controller

  alias Plover.Github

  def payload(conn, %{"payload" => payload}) do
    payload = Poison.decode!(payload)

    IO.puts "=-=-=-=-=-=-=-=-=-=-=-=-"
    case payload["action"] do
      "review_requested" ->
        Github.assign_pull_request(payload)
      _ ->
        IO.puts "It is:"
        IO.inspect payload.action
    end

    # payload
    # |> Poison.decode!
    # |> PullRequest.get_reviewers
    # |> PullRequest.pretty
    # |> Webhook.send

    IO.puts "=-=-=-=-=-=-=-=-=-=-=-=-"
    conn
    |> put_status(:ok)
    |> json(%{reponse: :ok})
  end
end
