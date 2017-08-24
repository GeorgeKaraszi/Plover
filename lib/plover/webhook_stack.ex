defmodule Plover.WebhookStack do
    @moduledoc false
    use GenServer
    alias Plover.Review.{Assigned, Submited}
    alias Plover.{Account, Slack, Github.PullRequest}

      # Client
      def start_link(state \\ []) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
      end

      def init(process) do
        {:ok, process}
      end

      def submit_request(payload, channel_name) do
        GenServer.cast(__MODULE__, {:push, {payload, channel_name}})
      end

      def post_results do
        GenServer.call(__MODULE__, :pop)
      end

      # Server (callbacks)

      def handle_call(:pop, _from, []) do
        {:reply, {:error, "empty results"}, []}
      end

      def handle_call(:pop, _from, [request | tail]) do
        results = process_request(request)
        {:reply, results, tail}
      end

      def handle_call(request, from, state) do
        # Call the default implementation from GenServer
        super(request, from, state)
      end

      def handle_cast({:push, item}, state) do
        {:noreply, [item | state]}
      end

      def handle_cast(request, state) do
        super(request, state)
      end

      defp process_request({payload, channel_name}) do
        case payload["action"] do
          action when action in ["review_requested", "review_request_removed"] ->
            payload
            |> Assigned.review(preload: true)
            |> submit_to_slack(channel_name)
          "submited" ->
            payload
            |> Submited.review()
            |> submit_to_slack(channel_name)
          _ ->
            {:error, "undefined action"}
        end
      end

      defp submit_to_slack({:error, _message} = data, _), do: data
      defp submit_to_slack({action, owner, pull_url}, channel_name) do
        Slack.post_to_slack!(owner, pull_url, action, channel_name)
      end
      defp submit_to_slack(%PullRequest{} = pull_request, channel_name) do
        unless Enum.empty?(pull_request.users) do
          pull_request.users
          |> Account.pluck_slack_logins()
          |> Slack.post_to_slack!(pull_request.url, "pull_request", channel_name)
        end
      end
    end
