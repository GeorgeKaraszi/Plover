defmodule GithubWebhook do
  @moduledoc false
  use GenServer

  alias Integration.Github.Payload

  require Logger

    # Client
    def start_link(state \\ []) do
      GenServer.start_link(__MODULE__, state, name: __MODULE__)
    end

    @doc """
      Find's the process for a given payload
    """
    def find_process(%Payload{} = payload) do
      GenServer.call(__MODULE__, {:retrieve, payload})
    end

    # Server (callbacks)

    def init(state) do
      {:ok, state}
    end

    def handle_call({:retrieve, payload}, _from, state) do
      case payload.pull_url do
        nil ->      {:reply, {:error, {:empty_name, "Empty pull url"}}, state}
        pull_url -> {:reply, get_worker(pull_url), state}
      end
    end

    @doc """
      Returns the existing or creates a new process for handeling pull requests
    """
    def get_worker(name) do
      process_name = convert_name(name)

      case Process.whereis(process_name) do
        nil ->
          Supervisor.start_child(Github.Supervisor, [[name: process_name]])
        pid -> pid
      end
    end

    def convert_name(name) when is_binary(name) do
      String.to_atom(name)
    end
    def convert_name(name), do: name

    #### OLD DATA TO REFERENCE ####
    # defp process_request({"submitted", payload}) do
    #   Submitted.review(payload)
    # end

    # defp process_request("review_request_removed", payload) do
    #   Assigned.review(payload)
    # end

    # defp process_request("review_requested", payload) do
    #   Assigned.review(payload)
    # end

    # defp submit_to_slack({:error, _message} = data, _), do: data

    # defp submit_to_slack({action, owner, pull_url}, channel_name) do
    #   Slack.post_to_slack!(owner, pull_url, action, channel_name)
    # end

    # defp submit_to_slack(%PullRequest{} = pull_request, channel_name) do
    #   unless Enum.empty?(pull_request.users) do
    #     pull_request.users
    #     |> Account.pluck_slack_logins()
    #     |> Slack.post_to_slack!(pull_request.url, "pull_request", channel_name)
    #   end
    # end
end
