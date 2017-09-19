defmodule Plover.Github.State do
    @moduledoc """
        Structure for what each worker will use to control their given pull request's
    """
    defstruct reviewers: [], state: [], pull_request_url: nil
end
