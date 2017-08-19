defmodule Plover.WebhookStack do
    @moduledoc false
    use GenServer
    alias Plover.Review.{Assigned, Submited}
    alias Plover.{Account, Slack}

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
            |> submit_to_slack(:review_request, channel_name)
          "submited" ->
            payload
            |> Submited.review()
            |> submit_to_slack(:submited, channel_name)
          _ ->
            {:error, "undefined action"}
        end
      end

      defp submit_to_slack(pull_request, :review_request, channel_name) do
        unless Enum.empty?(pull_request.users) do
          pull_request.users
          |> Account.pluck_slack_logins()
          |> Slack.post_review_request!(pull_request.url, channel_name: channel_name)
        end
      end

      defp submit_to_slack({action, reviewer, reviewers}, :submited, channel_name) do
        case action do
          "approved" ->
            1
          "changes_requested" ->
            2
            _unknown ->
              {:error, "unknown action for submit_to_slack"}
        end
      end
    end
