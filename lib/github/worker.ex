defmodule Github.Worker do
    @moduledoc false
    use GenServer
    require Logger
    alias Github.{Handel, State}
    alias Slack.RealTimeMessenger

    def start_link(state \\ %State{}, opts \\ []) do
        state = %{state | pull_request_url: Atom.to_string(opts[:name])}
        GenServer.start_link(__MODULE__, state, opts)
    end

    def init(state \\ %State{}) do
        {:ok, state}
    end

    @doc """
        Request changes to the current state of the Pull Request
    """
    def submit_changes({:ok, pid}, payload),   do: submit_changes(pid, payload)
    def submit_changes({status, response}, _), do: {:error, {status, response}}
    def submit_changes(pid, payload) do
        GenServer.cast(pid, {:change, payload})
    end

    @doc """
        Request current state of the Pull Request
    """
    def fetch_state(pid) do
        GenServer.call(pid, :fetch_state)
    end

    # Callback

    @doc """
        Modifies the current state of the Pull Request
    """
    def handle_cast({:change, payload}, state) do
        if payload.has_been_merged do
            {:stop, :normal, state}
        else
            payload
            |> Handel.process(state)
            |> handle_process_return_state()
        end
    end

    @doc """
        Returns the current state of the Pull Request
    """
    def handle_call(:fetch_state, _from, state) do
        {:reply, {:ok, state}, state}
    end

    # HOW TO HANDEL TERMINATING YOUR PROCESS W/O restarting
    def handle_call(:terminate, _from, state) do
        {:stop, :normal, state}
    end

    defp handle_process_return_state(state) do
        if Enum.empty?(state.targeted_users) do
            {:stop, :normal, state}
        else
            RealTimeMessenger.post_message(state)
            {:noreply, state}
        end
    end
end
