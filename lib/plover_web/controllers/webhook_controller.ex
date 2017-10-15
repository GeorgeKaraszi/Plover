defmodule PloverWeb.WebhookController do
  require Logger
  use PloverWeb, :controller

  alias Github.Worker

  @name __MODULE__ # Assigns the current module name globally

  def payload(conn, %{"payload" => raw_payload}) do
    payload = parsed_payload(raw_payload)
    results =
      payload
      |> Github.find_process()
      |> Worker.submit_changes(payload)

    case results do
      :ok ->
        response = log_response(results)
        conn |> put_status(:ok) |> json(%{reponse: response})
      error ->
        response = log_response(error, :error)
        conn |> put_status(:ok) |> json(%{reponse: response})
    end
  end

  def payload(conn, params) do
    response = log_response(params, :bad_request)

    conn
    |> put_status(:bad_request)
    |> json(%{reponse: response, reason: "Unknown Parameter"})
  end

  defp parsed_payload(payload) do
    payload
    |> Poison.decode!()
    |> PayloadParser.request_details()
  end

  defp log_response(response, type \\ :info) do
    inspected_response = inspect(response)

    case type do
      :info ->
        Logger.info "SUCCESS(#{@name}): #{inspected_response}"
      :bad_request ->
        Logger.info "UNKNOWN REQUEST(#{@name}): #{inspected_response}"
      _ ->
        Logger.error "ERROR(#{@name}): #{inspected_response}"
    end

    inspected_response
  end
end
