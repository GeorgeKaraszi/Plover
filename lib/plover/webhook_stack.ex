defmodule Plover.WebhookStack do
    @moduledoc false
    use GenServer
    alias Plover.Review.{Assigned, Submitted}
    alias Plover.{Account, Slack, Github.PullRequest}
    alias Integration.Github.Payload
    alias Plover.Github.Worker

    require Logger

      # Client
      def start_link(state \\ []) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
      end

      # Async Push to the stack
      def submit_request(%Payload{} = payload, channel_name) do
        GenServer.cast(__MODULE__, {:submit, payload})
      end

      # Sync Pop from the state
      def post_results do
        GenServer.call(__MODULE__, :pop)
      end

      def get_results(payload) do
        GenServer.call(__MODULE__, {:retrieve, payload})
      end

      # Server (callbacks)

      def init(state) do
        {:ok, state}
      end

      def handle_call({:retrieve, payload}, _from, state) do
        results = payload.pull_url
                  |> get_worker()
                  |> Worker.submitted_changes(payload)

        {:reply, results, state}
      end

      def handle_call(:pop, _from, []) do
        {:reply, {:error, "empty results"}, []}
      end

      def handle_call(:pop, _from, [request | tail]) do
        # results = process_request(request)
        {:reply, request, tail}
      end

      def handle_cast({:push, payload}, state) do


        {:noreply, state}
      end

      def get_worker(name) do
        process_name = String.to_atom(name)

        case Process.whereis(process_name) do
          nil ->
            Supervisor.start_child(Plover.Github.Supervisor, [[name: process_name]])
          pid -> pid
        end
      end


      defp log_request(worker_name, command) do
        Logger.info "LOGGED RESULTS: [#{get_worker worker_name}]: #{inspect command}"
      end

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
