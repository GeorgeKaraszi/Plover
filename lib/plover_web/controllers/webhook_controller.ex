defmodule PloverWeb.WebhookController do
  use PloverWeb, :controller

  alias Plover.Github

  def payload(conn, %{"payload" => payload}) do
    IO.puts "=-=-=-=-=-=-=-=-=-=-=-=-"
    payload
    |> Poison.decode!
    |> Github.assign_pull_request
    |> IO.inspect

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
