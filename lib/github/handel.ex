defmodule Github.Handel do
    @moduledoc """
        Handels each request that comes through to a Github Worker
    """
    alias Github.State
    alias Plover.Account
    alias PayloadParser.Payload

    @doc """
       Handels the payload actions for a Github worker's request
    """
    def process(payload \\ %Payload{}, state \\ %State{}) do
        payload
        |> process_request(state)
        |> assign_owner(payload.pull_owner)
        |> process_message_type(payload.action, payload.review_state)
        |> record_action()
    end

    @doc """
       Processes the request based on the supplied action state

       Returns: new state from the response
    """
    def process_request(%Payload{action: action} = payload, state) do
        case action do
            "submitted" ->
                change_user_state(state, payload.reviewer, payload.review_state)
            "review_request_removed" ->
                remove_reviewer(state, payload.requested_reviewer)
            _action ->
                assign_reviewer(state, payload.requested_reviewer, action)
        end
    end

    @doc """
        Assigns the pull request's owner to the pull request's state

        Returns: a new state containing the pull request owner or the current state if one exists
    """
    def assign_owner(state, nil), do: state
    def assign_owner(state, pull_owner) do
       if Enum.empty?(state.owners) do
        owners = pull_owner |> Account.find_by_github() |> reviewer("owner")
        %{state | owners: owners}
       else
        state
       end
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
    def find_missing_login(_user_list, nil), do: nil
    def find_missing_login(user_list, github_login) when is_list(user_list) do
        if List.keyfind(user_list, github_login, 0) do
            nil
        else
            Account.find_by_github(github_login)
        end
    end

    @doc """
       Assigns new reviewers to the given state

       Returns: new state with designated list of reviewers
    """

    def assign_reviewer(_state, nil, _user_state), do: []
    def assign_reviewer(state, github_login, user_state) do
        reviewer = state.reviewers
                   |> find_missing_login(github_login)
                   |> reviewer(user_state)
        %{state | reviewers: state.reviewers ++ reviewer}
    end

    @doc """
       Assigns the message type that is used for submitting to the slack messanger

       if the review state is approved. It will ensure ALL users have approved the PR
       before return "fully_approved", else it returns only a "partial_approval" type

       Returns: new state with a newly assigned message type and targeted audience
    """
    def process_message_type(state, message_action, nil) do
        message_type = message_action_inspector(state.reviewers, message_action)
        %{state | message_type: message_type, targeted_users: state.reviewers}
    end

    def process_message_type(state, _message_action, review_state) do
        message_type = message_action_inspector(state.reviewers, review_state)
        %{state | message_type: message_type, targeted_users: state.owners}
    end

    @doc """
        Records the history of the pull request, for each event that was occured during
        the life span of the project
    """
    def record_action(state) do
        %{state | action_history: [state.message_type | state.action_history]}
    end

    @doc """
       Setups the tuple structure that will house a provided user

       if the review state is approved. It will ensure ALL users have approved the PR
       before return "fully_approved", else it returns only a "partial_approval" type

       Returns: a list of a single tuple containing the reviewer's information

       #Example
       iex> %{github_login: "georgekaraszi", slack_login: "@george"}
       iex> Github.Handel.reviewer("approved")
       [{"georgekaraszi", "@george", "approved"}]
    """
    def reviewer(nil, _user_state), do: []
    def reviewer(user, user_state) do
        [{user.github_login, user.slack_login, user_state}]
    end

    defp message_action_inspector(_, nil), do: nil
    defp message_action_inspector(reviewers, action) do
        case action do
            "approved"               -> approval_count(reviewers)
            "review_request_removed" -> approval_count(reviewers)
            "review_requested"       -> "pull_request"
            _fallback                -> action
        end
    end

    defp approval_count(reviewers) do
        total_count    = Enum.count(reviewers)
        approval_count = Enum.reduce(reviewers, 0, fn(r, acc) ->
            if elem(r, 2) == "approved", do: acc + 1, else: acc
        end)

        cond do
            approval_count == 0          -> "pull_request"
            approval_count < total_count -> "partial_approval"
            true                         -> "fully_approved"
        end
    end
end
