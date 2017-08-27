defmodule Plover.Commands.CrudCommands do
    @moduledoc """
        Macro for creating reusable CRUD commands that can be included to each set of schema commands
    """
    alias Plover.Repo

    defmacro __using__(_) do
        quote do
            def associations,               do: __MODULE__.__schema__(:associations)
            def preload(changeset),         do: Repo.preload(changeset, associations())
            def all,                        do: Repo.all(__MODULE__)
            def find(record_id),            do: Repo.get(__MODULE__, record_id)
            def find!(record_id),           do: Repo.get!(__MODULE__, record_id)
            def find_by(query),             do: Repo.get_by(__MODULE__ , query)
            def count,                      do: Repo.aggregate(__MODULE__ , :count, :id)
            def count_by(field \\ :id),     do: Repo.aggregate(__MODULE__ ,:count, field)
            def order_by_latest,            do: from q in __MODULE__, order_by: [desc: q.inserted_at]
            def delete!(record_id),         do: record_id |> find! |> Repo.delete!
            def destroy_all!,               do: Repo.delete_all(from r in __MODULE__)
            def update(old_record_id, record) do
                old_record_id |> find |> changeset(record) |> Repo.update
            end
        end
    end
end
