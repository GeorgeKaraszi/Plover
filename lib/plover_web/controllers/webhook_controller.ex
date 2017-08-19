defmodule PloverWeb.WebhookController do
  require Logger
  use PloverWeb, :controller


  alias Plover.WebhookStack

  def payload(conn, %{"payload" => payload}) do
    decoded_payload =  Poison.decode!(payload)

    WebhookStack.submit_request(decoded_payload, System.get_env("SLACK_CHANNEL_NAME"))

    case WebhookStack.post_results do
      {:ok, response} ->
        Logger.info inspect(response)
      error ->
        Logger.error inspect(error)
    end

    conn |> put_status(:ok) |> json(%{reponse: :ok})
  end

  def payload(conn, _params) do
    conn |> put_status(:not_found) |> json(%{reponse: :bad_request})
  end
end
