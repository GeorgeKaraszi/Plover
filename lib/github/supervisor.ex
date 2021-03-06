defmodule Github.Supervisor do
    @moduledoc false

    use Supervisor
    alias Github.{State, Worker}

    @name __MODULE__

    def start_link(state \\ %State{}, name \\ @name) do
        Supervisor.start_link(@name, state, [name: name])
    end

    @doc """
        Initalizes what this supervisor's children will look like and start with
    """
    def init(state) do
        children = [worker(Worker, [state], restart: :transient)]
        supervise(children, strategy: :simple_one_for_one)
    end
end
