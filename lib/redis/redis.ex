defmodule Redis do
    @moduledoc """
        Handels the connection for sending and retrieving data from redis
    """

    use GenServer
    alias Github.State

    @spec start_link(String.t | nil) :: GenServer.on_start()
    def start_link(redis_uri) do
        GenServer.start_link(__MODULE__, redis_uri, name: __MODULE__)
    end

    def init(redis_uri) do
        case redis_uri do
            nil -> Redix.start_link()
            uri -> Redix.start_link(uri)
        end
    end

    @spec retrieve(String.t) :: {:ok, %State{} | nil}
    def retrieve(key) do
        GenServer.call(__MODULE__, {:retrieve, key})
    end

    @spec submit(%State{}, String.t) :: %State{}
    def submit(state, identifier) do
        GenServer.cast(__MODULE__, {:submit, identifier, state})
        state
    end

    @spec destroy(String.t) :: :ok
    def destroy(key) do
        GenServer.cast(__MODULE__, {:destroy, key})
    end

    def destroy_all! do
        GenServer.cast(__MODULE__, {:destroy_all})
    end

    # callbacks

    def handle_call({:retrieve, key}, _from, conn) do
        case Redix.command(conn, ["GET", key]) do
            {_, nil}           -> {:reply, {:ok, nil}, conn}
            {_, encoded_value} -> {:reply, Poison.decode(encoded_value, as: %State{}), conn}
        end
    end

    def handle_cast({:submit, key, state_value}, conn) do
        encoded_value = Poison.encode!(state_value)

        Redix.command(conn, ["SET", key, encoded_value])
        {:noreply, conn}
    end

    def handle_cast({:destroy, key}, conn) do
        Redix.command(conn, ["DEL", key])
        {:noreply, conn}
    end

    def handle_cast({:destroy_all}, conn) do
        Redix.command(conn, ["FLUSHALL"])
        {:noreply, conn}
    end
end
