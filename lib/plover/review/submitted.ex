defmodule Plover.Review.Submitted do
    @moduledoc """
        Parses the requrements for submitting a slack message based on a `submit` response from github
    """

    alias Integration.Github.{PayloadParser, Payload}
    alias Plover.{Account, Account.User}

    @doc """
        Parses the requirements for processing a slack message based on the payload review state

        Returns
        - {state, pr_owner_slack, pull_url}
    """
    def review(%Payload{} = payload) do
        case payload.review_state do
            "approved" ->
                owner     = payload.pull_owner |> get_user()
                reviewers = payload.reviewers  |> get_users()
                review_return(payload.review_state, owner, reviewers, payload.pull_url)
            "changes_requested" ->
                owner     = payload.pull_owner |> get_user()
                reviewer  = payload.reviewer   |> get_user()
                review_return(payload.review_state, owner, reviewer, payload.pull_url)
            _ ->
                {:error, "unknown review state"}
        end
    end

    def review(raw_payload) do
        raw_payload |> PayloadParser.request_details() |> review()
    end

    @doc """
        Returns a list of slack login's for all queried git logins

        Example:
        iex> Plover.Factory.insert(:user, github_login: "gitlogin", slack_login: "@slacklogin")
        iex> Plover.Review.Submitted.get_users(["gitlogin"])
        ["@slacklogin"]
    """
    def get_users(reviewers) when is_list(reviewers) do
        reviewers
        |> Account.all_by_github_login()
        |> Account.pluck_slack_logins()
    end

    @doc """
        Returns a user's slack id that was found in the system

        Example:
        iex> Plover.Factory.insert(:user, github_login: "gitlogin", slack_login: "@slacklogin")
        iex> Plover.Review.Submitted.get_user("gitlogin")
        "@slacklogin"
    """
    def get_user(reviewer) do
        User.find_by(github_login: reviewer)
        |> Account.pluck_slack_logins()
    end

    defp review_return(_, nil, _, _), do: {:error, "Could not find slack id for Pull Request owner!"}
    defp review_return(state, owner, reviewers, pull_url) do
        case state do
            "approved" ->
                if is_list(reviewers) && Enum.any?(reviewers) do
                    {:error, "Not fully approved yet"}
                else
                    {state, owner, pull_url}
                end
            "changes_requested" ->
                {state, owner, pull_url}
            _ ->
                {:error, "unknown (#{state}) type"}
        end
    end
end
