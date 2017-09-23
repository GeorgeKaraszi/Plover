defmodule Github.Handel do
    @moduledoc """
        Handels each request that comes through to a Github Worker
    """
    alias Integration.Github.Payload
    alias Github.State
    alias Plover.Account

    @doc """
       Handels the payload actions for a Github worker's request
    """
    def process(payload \\ %Payload{}, state \\ %State{}) do
        payload.action
        |> process_request(payload, state)
        |> record_action(payload.action)
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
        assign_reviewers(state, payload.requested_reviewer, "review_requested")
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
       Removed a user from the reviewer's list

       Returns: new state without designated reviewer
    """
    def remove_reviewer(state, nil), do: state
    def remove_reviewer(state, github_login) do
        %{state | reviewers: List.keydelete(state.reviewers, github_login, 0)}
    end

    @doc """
       Performs a database lookup for accounts are not apart of the already establish list of reviewers

       Returns: nil if exists or not registered
    """
    def find_missing_login(_state, nil), do: nil
    def find_missing_login(state, github_login) do
        if List.keyfind(state.reviewers, github_login, 0) do
            nil
        else
            Account.find_by_github(github_login)
        end
    end

    @doc """
       Assigns new reviewers to the given state

       Returns: new state with designated list of reviewers
    """
    def assign_reviewers(_state, nil, _user_state), do: []
    def assign_reviewers(state, github_login, user_state) do
        reviewer = state |> find_missing_login(github_login) |> reviewer(user_state)
        %{state | reviewers: state.reviewers ++ reviewer}
    end

    defp reviewer(nil, _user_state), do: []
    defp reviewer(user, user_state) do
        [{user.github_login, user.slack_login, user_state}]
    end

    defp record_action(state, action) do
        %{state | action_history: [action | state.action_history]}
    end
end
