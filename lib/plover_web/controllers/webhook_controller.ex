defmodule PloverWeb.WebhookController do
  use PloverWeb, :controller

  alias Integration.{Github.PullRequest, Slack.Webhook}

  def payload(conn, %{"payload" => payload}) do
    # IO.puts "=-=-=-=-=-=-=-=-=-=-=-=-"

    payload
    |> Poison.decode!
    |> PullRequest.get_reviewers
    |> PullRequest.pretty
    |> Webhook.send

    # IO.puts "=-=-=-=-=-=-=-=-=-=-=-=-"
    conn
    |> put_status(:ok)
    |> json(%{reponse: :ok})
  end
end
