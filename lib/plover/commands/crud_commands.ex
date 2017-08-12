defmodule Plover.Commands.CrudCommands do
    @moduledoc """
        Macro for creating reusable CRUD commands that can be included to each set of schema commands
    """
    alias Plover.Repo

    defmacro __using__(record_type: record_type, associations: associations) do
        quote do
               def all(preload),               do: Repo.all from s in unquote(record_type), preload: unquote(associations)
               def all,                        do: Repo.all(unquote(record_type))
               def find(record_id, :preload),  do: record_id |> find()  |> Repo.preload(unquote(associations))
               def find(record_id),            do: unquote(record_type) |> Repo.get(record_id)
               def find!(record_id, :preload), do: record_id |> find! |> Repo.preload(unquote(associations))
               def find!(record_id),           do: unquote(record_type) |> Repo.get!(record_id)
               def find_by(query),             do: unquote(record_type) |> Repo.get_by(query)
               def count,                      do: unquote(record_type) |> Repo.aggregate(:count, :id)
               def count_by(field \\ :id),     do: unquote(record_type) |> Repo.aggregate(:count, field)
               def order_by_latest,            do: from q in unquote(record_type), order_by: [desc: q.inserted_at]
               def delete!(record_id),         do: record_id |> find! |> Repo.delete!
               def update(old_record_id, record) do
                   old_record_id |> find |> changeset(record) |> Repo.update
                end

              def destroy_all!, do: Repo.delete_all(from r in unquote(record_type))
        end
    end
end
