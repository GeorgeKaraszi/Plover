defmodule Github.State do
    @moduledoc """
        Structure for what each worker will use to control their given pull request's
    """

    defstruct [
        owners: [],
        reviewers: [],
        action_history: [],
        targeted_users: [],
        message_type: nil,
        pull_request_url: nil
    ]
end
