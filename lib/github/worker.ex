defmodule Plover.Github.Worker do
    @moduledoc false
    use GenServer
    require Logger
    alias Plover.Github.{State, Handel}

    def start_link(state \\ %State{}, opts \\ []) do
        state = %{state | pull_request_url: opts[:name]}
        GenServer.start_link(__MODULE__, state, opts)
    end

    def init(state \\ %State{}) do
        {:ok, state}
    end

    @doc """
        Request changes to the current state of the Pull Request
    """
    def submit_changes({:ok, pid}, payload), do: submit_changes(pid, payload)
    def submit_changes(pid, payload) do
        GenServer.call(pid, {:change, payload})
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
    def handle_call({:change, payload}, _from, state) do
        new_state = Handel.process(payload, state)
        {:reply, new_state, new_state}
    end

    @doc """
        Returns the current state of the Pull Request
    """
    def handle_call(:fetch_state, _from, state) do
        {:reply, state, state}
    end
end
