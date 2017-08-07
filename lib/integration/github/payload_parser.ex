defmodule Integration.Github.PayloadParser do
    @moduledoc """
        Extracts information from a github pull request
    """
    alias Integration.Github.{Payload}

    @doc """
        Returns the Organization's full name

        Returns
            - name if success
            - nil if name is not found
    """
    def organization_name(%{"organization" => %{"login" => name}}), do: name
    def organization_name(_), do: nil

    @doc """
        Returns the Organization urls

        Returns
            - url if success
            - nil if url is not found
    """
    def organization_url(%{"organization" => %{"url" => url}}), do: url
    def organization_url(_), do: nil
    @doc """
        Returns the Projects name

        Returns
            - name if success
            - nil if name is not found
    """
    def project_name(%{"repository" => %{"full_name" => name}}), do: name
    def project_name(_), do: nil

    @doc """
        Returns the Projects url

        Returns
            - url if success
            - nil if url is not found
    """
    def project_url(%{"repository" => %{"html_url" => url}}), do: url
    def project_url(_), do: nil

    @doc """
        Returns the pull request url

        Returns
            - url if success
            - nil if url is not found
    """
    def pull_url(%{"pull_request" => %{"url" => url}}), do: url
    def pull_url(_), do: nil

    @doc """
        Returns the pull request name

        Returns
            - name if success
            - nil if name is not found
    """
    def pull_name(%{"pull_request" => %{"title" => name}}), do: name
    def pull_name(_), do: nil

    @doc """
        Returns the pull request status

        Returns
            - status if success
            - nil if name is not found
    """
    def pull_status(%{"pull_request" => %{"state" => status}}), do: status
    def pull_status(_), do: nil

    @doc """
        Returns a list of reviewer login names

        Returns
            - List of login names
    """
    def reviewers(%{"pull_request" => pull_request}), do: reviewers(pull_request)
    def reviewers(%{"requested_reviewers" => reviewers}), do: reviewers(reviewers)
    def reviewers([%{"login" => login} | reviewers]), do: [login | reviewers(reviewers)]
    def reviewers([]), do: []

    @doc """
        Returns list of all avaiaible data in a PR

        Returns
            - %{...} if success
            - nil if failure
    """
    def request_details(payload) do
        %Payload{
            organization_name: organization_name(payload),
            organization_url: organization_url(payload),
            project_name: project_name(payload),
            project_url: project_url(payload),
            pull_name: pull_name(payload),
            pull_url: pull_url(payload),
            pull_status: pull_status(payload),
            reviewers: reviewers(payload),
        }
    end
end
