defmodule Plover.Github.WorkerTest do
    @moduledoc false
  use Plover.DataCase, async: true

  setup do
    payload = :github_payload |> build() |> with_reviewers(1)
    {:ok, pid} = Plover.WebhookStack.find_process(payload)
    [pid: pid, payload: payload]
  end

  describe "New"
end
