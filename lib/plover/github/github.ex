defmodule Plover.Github do
    @moduledoc false
    use Plover, :model
    alias Plover.Account
    alias Plover.Github.{Project, PullRequest, Review}
    alias Integration.Github.{PayloadParser, Payload}

    @doc """
        Esablishes links between Projects, Pull Requests and Reviewers
    """
    def assign_pull_request(%Payload{} = payload) do
        payload
        |> find_or_create_project
        |> find_or_create_pull_request(payload)
        |> assign_reviewers(payload)
    end

    def assign_pull_request(%{} = raw_payload) do
       raw_payload |> PayloadParser.request_details |> assign_pull_request
    end

    @doc """
        Remove all previous reviewers then replaces them with the new set
    """
    def assign_reviewers(%PullRequest{} = pull_request, %Payload{} = payload) do
        destroy_reviewers(pull_request)

        payload.reviewers
        |> Account.all_by_github_login
        |> new_reviewers(pull_request)
        |> create_reviewers
    end

    @doc """
        Mass inserts reviewers into the the Review schema
    """
    def create_reviewers(reviewers) do
        if Enum.any?(reviewers) do
            Repo.insert_all(Review, reviewers)
        end
    end


    @doc """
        Finds or creates a PR based on the PR's url

        Returns
            - {:ok, pull_request}
            - {:error, changeset}
    """
    def find_or_create_pull_request({:ok, %Project{} = project}, %Payload{} = payload) do
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
        attrs = project |> pull_request_changeset(payload)
        %PullRequest{} |> PullRequest.changeset(attrs) |> Repo.insert()
    end

    @doc """
        creates a new pull request

        Returns
            - {:ok, project}
            - {:error, changeset}
    """
    def create_project(%Payload{} = payload) do
        attrs = payload |> project_changeset
        %Project{} |> Project.changeset(attrs) |> Repo.insert()
    end


    defp new_reviewers([], _), do: []
    defp new_reviewers([user | users], pull_request) do
        changeset =
            user
            |> reviewer_changeset(pull_request)
            |> Review.changeset

        [changeset | new_reviewers(users, pull_request)]
    end

    defp project_changeset(payload) do
        %{
            name: payload.project_name,
            url: payload.project_url,
            organization_name: payload.organization_name,
            organization_url: payload.organization_url
        }
    end

    defp pull_request_changeset(project, payload) do
        %{
            name: payload.pull_name,
            url: payload.pull_url,
            status: payload.pull_status,
            github_project: project,
        }
    end

    defp reviewer_changeset(user, pull_request) do
        %{
            user: user,
            pull_request: pull_request
        }
    end

    defp destroy_reviewers(pull_request) do
        Repo.delete_all(
            from r in Review,
            where: [github_pull_request_id: ^pull_request.id]
        )
    end
end