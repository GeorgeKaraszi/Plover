defmodule Github.Worker do
    @moduledoc false
    use GenServer
    require Logger
    alias Github.{Handel, State}
    alias PayloadParser.Payload

    @spec start_link(%State{}, Keyword.t()) :: GenServer.on_start()
    def start_link(state, opts) do
        state = %{state | pull_request_url: Atom.to_string(opts[:name])}
        GenServer.start_link(__MODULE__, state, opts)
    end

    def init(%State{pull_request_url: url} = state) do
        {:ok, recovery_state} = Redis.retrieve(url)
        {:ok, recovery_state || state}
    end

    @doc """
        Request changes to the current state of the Pull Request
    """
    @spec submit_changes(GenServer.server(), %Payload{}) :: :ok | {:error, String.t}
    def submit_changes({:ok, pid}, payload),   do: submit_changes(pid, payload)

    def submit_changes({:error, response}, _), do: {:error, response}

    def submit_changes(pid, payload) do
        GenServer.cast(pid, {:change, payload})
    end

    @doc """
        Request current state of the Pull Request
    """
    @spec fetch_state(GenServer.server()) :: {:ok, %State{}}
    def fetch_state(pid) do
        GenServer.call(pid, :fetch_state)
    end

    # Callback

    @doc """
        Modifies the current state of the Pull Request
    """
    def handle_cast({:change, payload}, state) do
        if payload.has_been_closed || payload.has_been_merged do
            close_worker(state)
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

    defp handle_process_return_state(state) do
        if Enum.empty?(state.targeted_users) do
            close_worker(state)
        else
            state
            |> Redis.submit(state.pull_request_url)
            |> SlackMessenger.post_message()
            {:noreply, state}
        end
    end

    defp close_worker(%State{pull_request_url: url} = state) do
        Redis.destroy(url)
        SlackMessenger.destroy_messages(state)
        {:stop, :normal, state}
    end
end
