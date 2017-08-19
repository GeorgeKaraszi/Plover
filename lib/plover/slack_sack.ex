defmodule Plover.SlackStack do
    @moduledoc false
    use GenServer
    alias Plover.{Account, Slack}

      # Client
      def start_link(state \\ []) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
      end

      def init(process) do
        {:ok, process}
      end

      def submit_request(item) do
        GenServer.cast(__MODULE__, {:push, item})
      end

      def post_request do
        GenServer.call(__MODULE__, :pop)
      end

      # Server (callbacks)

      def handle_call(:pop, _from, []) do
        {:reply, {:error, "empty results"}, []}
      end

      def handle_call(:pop, _from, [item | tail]) do
        results = process_slack_item(item)
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

      defp process_slack_item({[], _, _}), do: nil
      defp process_slack_item({users, pull_url, channel_name}) do
        users
        |> Account.pluck_slack_logins()
        |> Slack.update_or_create_message!(pull_url, channel_name: channel_name)
      end
    end
