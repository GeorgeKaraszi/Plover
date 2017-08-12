defmodule PloverWeb.WebhookController do
  use PloverWeb, :controller

  alias Plover.{Github, Slack, Account}

  def payload(conn, %{"payload" => payload}) do
    payload = Poison.decode!(payload)

    case payload["action"] do
      action when action in ["review_requested", "review_request_removed"] ->
        pull_request = Github.assign_pull_request(payload, preload: true)
        post_to_slack(pull_request.users, pull_request.url)
      _ ->
        IO.puts "unknown action"
    end

    conn |> put_status(:ok) |> json(%{reponse: :ok})
  end

  def payload(conn, _params) do
    conn |> put_status(:not_found) |> json(%{reponse: :bad_request})
  end

  defp post_to_slack([], _), do: nil
  defp post_to_slack(users, pull_url) when is_list(users) do
    channel_name = System.get_env("SLACK_CHANNEL_NAME")

    users
    |> Account.pluck_slack_logins()
    |> Slack.update_or_create_message!(pull_url, channel_name: channel_name)
  end
end
