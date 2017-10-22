ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Plover.Repo, :manual)

[:ex_machina, :timex]
|> Enum.each(fn x -> {:ok, _} = Application.ensure_all_started(x) end)
