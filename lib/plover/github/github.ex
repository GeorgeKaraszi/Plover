defmodule Plover.Github do
    @moduledoc false
    use Plover, :model
    alias Plover.Account
    alias Plover.Github.{Project, PullRequest, Review}
    alias Integration.Github.{PayloadParser, Payload}
    alias Ecto.Multi

    @doc """
        Esablishes links between Projects, Pull Requests and Reviewers
    """
    def assign_pull_request(%Payload{} = payload) do
        payload
        |> find_or_create_project
        |> find_or_create_pull_request(payload)
        |> assign_reviewers(payload)
    end

    def assign_pull_request(raw_payload) do
       raw_payload |> PayloadParser.request_details() |> assign_pull_request()
    end

    @doc """
        Remove all previous reviewers then replaces them with the new set
    """
    def assign_reviewers({:ok, pull_request}, payload) do
        assign_reviewers(pull_request, payload)
    end

    def assign_reviewers(%PullRequest{} = pull_request, %Payload{} = payload) do
        destroy_reviewers(pull_request)

        payload.reviewers
        |> Account.all_by_github_login()
        |> create_reviewers(pull_request)
    end

    @doc """
        Mass inserts reviewers into the the Review schema
    """
    def create_reviewers(reviewers, pull_request, multi \\ Multi.new) do
        multi |> new_reviewers(reviewers, pull_request) |> Repo.transaction
    end

    @doc """
        Finds or creates a PR based on the PR's url

        Returns
            - {:ok, pull_request}
            - {:error, changeset}
    """
    def find_or_create_pull_request({:ok, project}, payload) do
        find_or_create_pull_request(project, payload)
    end

    def find_or_create_pull_request(%Project{} = project, %Payload{} = payload) do
        case PullRequest.find_by(url: payload.pull_url) do
            nil -> create_pull_request(project, payload)
            pull_request -> {:ok, pull_request}
        end
    end

    @doc """
        Finds or creates a project based on the project's url

        Returns
            - {:ok, project}
            - {:error, changeset}
    """
    def find_or_create_project(%Payload{project_url: url} = payload) do
        case Project.find_by(url: url) do
            nil -> create_project(payload)
            project -> {:ok, project}
        end
    end

    @doc """
        creates a new pull request

        Returns
            - {:ok, pull_request}
            - {:error, changeset}
    """
    def create_pull_request(%Project{} = project, %Payload{} = payload) do
        project |> PullRequest.changeset_payload(payload) |> Repo.insert()
    end

    @doc """
        creates a new pull request

        Returns
            - {:ok, project}
            - {:error, changeset}
    """
    def create_project(%Payload{} = payload) do
        payload |> Project.changeset_payload() |> Repo.insert()
    end

    defp new_reviewers(multi, [], _), do: multi
    defp new_reviewers(multi, [user | users], pull_request) do
        changeset = user |> Review.changeset_payload(pull_request)

        multi
        |> Multi.insert(:review, changeset)
        |> new_reviewers(users, pull_request)
    end

    defp destroy_reviewers(pull_request) do
        Repo.delete_all(
            from r in Review,
            where: [github_pull_request_id: ^pull_request.id]
        )
    end
end
