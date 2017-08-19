defmodule PloverWeb.WebhookController do
  require Logger
  use PloverWeb, :controller


  alias Plover.{GithubStack, SlackStack}

  def payload(conn, %{"payload" => payload}) do
    payload
    |> Poison.decode!()
    |> GithubStack.submit_request()

    case GithubStack.get_results do
      {:ok, pull_request} ->
        {pull_request.users, pull_request.url, System.get_env("SLACK_CHANNEL_NAME")}
        |> SlackStack.submit_request()

        SlackStack.post_request
      error ->
        Logger.error inspect(error)
    end

    conn |> put_status(:ok) |> json(%{reponse: :ok})
  end

  def payload(conn, _params) do
    conn |> put_status(:not_found) |> json(%{reponse: :bad_request})
  end
end
