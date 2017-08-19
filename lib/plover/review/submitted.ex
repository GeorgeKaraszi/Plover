defmodule Plover.Review.Submitted do
    @moduledoc false

    alias Integration.Github.{PayloadParser, Payload}
    alias Plover.Account

    def review(%Payload{} = payload) do
        case payload.review_state do
            "approved" ->
                {:approved, payload.review}
            "changes_requested" ->
                1
            _ ->
                2
        end
    end

    def review(raw_payload) do
        raw_payload |> PayloadParser.request_details() |> review()
    end


    def get_github_ids(payload) do
    end


end
