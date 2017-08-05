defmodule Integration.Github.PullRequest do
    @moduledoc false

    @doc """
        Returns the pull request url
    """
    def get_pull_url(%{"pull_request" => pull_request}), do: __MODULE__.get_pull_url(pull_request)
    def get_pull_url(%{"url" => url}), do: url

    @doc """
        Returns a list of reviewer login names
    """
    def get_reviewers(%{"pull_request" => pull_request}), do: __MODULE__.get_reviewers(pull_request)
    def get_reviewers(%{"requested_reviewers" => reviewers}), do: __MODULE__.get_reviewers(reviewers)
    def get_reviewers([]), do: []
    def get_reviewers([reviewer | reviewers]) do
        %{"login" => login} = reviewer
        [login | get_reviewers(reviewers)]
    end

    def pretty([]), do: " "
    def pretty([l | t]) do
        l <> ", " <> pretty(t)
    end
end
