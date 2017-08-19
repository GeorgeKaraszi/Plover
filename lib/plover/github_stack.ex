defmodule Plover.GithubStack do
    @moduledoc false
    use GenServer
    alias Plover.Github

      # Client
      def start_link(state \\ []) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
      end

      def init(process) do
        {:ok, process}
      end

      def submit_request(payload) do
        GenServer.cast(__MODULE__, {:push, payload})
      end

      def get_results do
        GenServer.call(__MODULE__, :pop)
      end

      # Server (callbacks)

      def handle_call(:pop, _from, []) do
        {:reply, {:error, "empty results"}, []}
      end

      def handle_call(:pop, _from, [payload | tail]) do
        results = process_payload(payload)
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

      defp process_payload(payload) do
        case payload["action"] do
          action when action in ["review_requested", "review_request_removed"] ->
            pull_request = Github.assign_pull_request(payload, preload: true)
            {:ok, pull_request}
          _ ->
            {:error, "undefined action"}
        end
      end
    end
