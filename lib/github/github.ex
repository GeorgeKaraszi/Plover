defmodule Github do
    @moduledoc false
    use GenServer
    alias PayloadParser.Payload

      # Client
      def start_link(state \\ []) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
      end

      def init(state) do
        {:ok, state}
      end

      @doc """
        Find's the process for a given payload
      """
      @spec find_process(Payload.t) :: {:error, {atom(), String.t}} | GenServer.server()
      def find_process(payload) do
        GenServer.call(__MODULE__, {:retrieve, payload})
      end

      @spec start_process(String.t) :: {:ok, {atom(), String.t} | GenServer.server()}
      def start_process(pull_url) do
        GenServer.call(__MODULE__, {:start_process, pull_url})
      end

      # Server (callbacks)

      def handle_call({:retrieve, payload}, _from, state) do
        case valid?(payload) do
          {:error, message} -> {:reply, {:error, message}, state}
          _true             -> {:reply, get_worker(payload.pull_url), state}
        end
      end

      def handle_call({:start_process, pull_url}, _from, state) do
        {:reply, get_worker(pull_url), state}
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

      @doc """
        Converts a string into an atom. Atom's are required for processes to be found by their name.
      """
      def convert_name(name) when is_binary(name) do
        String.to_atom(name)
      end
      def convert_name(name), do: name

      @doc """
        Validates that the payload contains the correct values we want to process
      """
      def valid?(%Payload{pull_url: pull_url, action: action} = payload) do
        cond do
          pull_url == nil ->
            {:error, {:empty_name, "Empty pull url"}}
          action == nil ->
            {:error, {:empty_action, "Empty action"}}
          action not in ["submitted", "review_requested", "review_request_removed", "closed"] ->
            {:error, {:unknown_action, "Do not understand (#{action}) action"}}
          true ->
            {:ok, payload}
        end
      end
  end
