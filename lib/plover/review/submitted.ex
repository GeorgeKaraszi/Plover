defmodule Plover.Review.Submited do
    @moduledoc false

    alias Integration.Github.{PayloadParser, Payload}
    alias Plover.{Account, Account.User}

    def review(%Payload{} = payload) do
        case payload.review_state do
            state when state in ["approved", "changes_requested"] ->
                reviewers = payload.reviewers |> get_users()
                reviewer  = payload.review    |> get_user()
                review_return(state, reviewer, reviewers)
            _ ->
                {:error, "unknown review state"}
        end
    end

    def review(raw_payload) do
        raw_payload |> PayloadParser.request_details() |> review()
    end

    def get_users(reviewers) do
        Account.all_by_github_login(reviewers)
    end

    def get_user(reviewer) do
        User.find_by(github_login: reviewer)
    end

    defp review_return(nil, _), do: {:error, "Could not find reviewer"}
    defp review_return(action, reviewer, reviewers) do
        {action, reviewer, reviewers}
    end
end
