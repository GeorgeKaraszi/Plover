defmodule Github.State do
    @moduledoc """
        Structure for what each worker will use to control their given pull request's
    """
    defstruct reviewers: [], action_history: [], pull_request_url: nil
end
