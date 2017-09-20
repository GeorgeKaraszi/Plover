defmodule Plover.Github.Handel do
    @moduledoc """
        Handels each request that comes through to a Github Worker
    """
    alias Integration.Github.Payload
    alias Plover.Github.State
    alias Plover.Account

    @doc """
       Handels the payload actions for a Github worker's request
    """
    def process(payload \\ %Payload{}, state \\ %State{}) do
        payload.action
        |> process_request(payload, state)
        |> assign_state(payload.action)
    end

    @doc """
       Processes the request based on the supplied action state

       Returns: new state from the response
    """
    def process_request("submitted", _payload, state) do
        state
    end

    def process_request("review_request_removed", payload, state) do
        remove_reviewer(state, payload.requested_reviewer)
    end

    def process_request("review_requested", payload, state) do
        assign_reviewers(state, payload.reviewers, "review_requested")
    end

    @doc """
       Changes the state of an existing user

       Returns: New state containing the modified user state.
    """
    def change_user_state(state, github_login, user_state) do
        user = List.keyfind(state.reviewers, github_login, 0)

        if user do
            user = user
                   |> Tuple.delete_at(2)
                   |> Tuple.insert_at(2, user_state)
            %{state | reviewers: List.keyreplace(state.reviewers, github_login, 0, user)}
        else
            state
        end
    end

    @doc """
       Assigns new reviewers to the given state

       Returns: new state with designated list of reviewers
    """
    def assign_reviewers(state, github_logins, user_state) do
        new_reviewers = state
                        |> find_missing_logins(github_logins)
                        |> assign_reviewers(user_state)

        %{state | reviewers: state.reviewers ++ new_reviewers}
    end

    @doc """
       Removed a user from the reviewer's list

       Returns: new state without designated reviewer
    """
    def remove_reviewer(state, nil), do: state
    def remove_reviewer(state, github_login) do
        %{state | reviewers: List.keydelete(state.reviewers, github_login, 0)}
    end

    @doc """
       Looks for reviewers that have not yet been added to the reviewer's list

       Returns: ["github_login1", "github_login2", ...] or []
    """
    def find_missing_logins(_state, []), do: []
    def find_missing_logins(state, [github_login | tail]) do
        if List.keyfind(state.reviewers, github_login, 0) do
            find_missing_logins(state, tail)
        else
            [github_login | find_missing_logins(state, tail)]
        end
    end

    @doc """
        Performs a database lookup for accounts that contain a provided list of github logins

        Note: If github login is not registered, then the reviewer is not returned!

        Returns: [{:github_login, :slack_login, :user_state}, ...]
    """
    def assign_reviewers([]), do: []
    def assign_reviewers(github_logins, user_state) do
        github_logins
        |> Account.all_by_github_login()
        |> Enum.map(fn account -> reviewer(account, user_state) end)
    end

    defp reviewer(user, user_state) do
        {user.github_login, user.slack_login, user_state}
    end

    defp assign_state(state \\ %State{}, action) do
        %{state | state: [action | state.state]}
    end
end
