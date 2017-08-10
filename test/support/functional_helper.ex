defmodule Plover.FunctionalHelper do
    @moduledoc false
    use ExUnit.CaseTemplate

    @doc """
        Runs assertion checks on the subject function before and after the action function is ran

        subject = fn -> Repo.aggregate(User, :id, :count) end
        action  = fn -> insert(:user) end
        changed(subject, action, by: 1)
    """
    def changed(subject, action, by: by) do
        [inital, then] = run_action(subject, action)
        refute then == inital
        assert then == inital + by
    end

    @doc """
        Runs assertion checks on the subject function before and after the action function is ran.

        This will check to see if the inital subject response has the same value `from`.
        Then it will check the subject again after the `action` function has ran to see if it has
         change to the specified `to` value

        subject = fn -> Repo.aggregate(User, :id, :count) end
        action  = fn -> insert(:user) end
        changed(subject, action, from: 0, to: 1)
    """
    def changed(subject, action, from: from, to: to) do
        [inital, then] = run_action(subject, action)
        assert inital == from
        assert then == to
    end

    defp run_action(subject, action) do
        inital = subject.()
        action.()
        then  = subject.()
        [inital, then]
    end
end
