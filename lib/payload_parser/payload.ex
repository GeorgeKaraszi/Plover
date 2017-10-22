defmodule PayloadParser.Payload do
    @moduledoc false

    @type t :: %__MODULE__{
        action: String.t,
        organization_name: String.t,
        organization_url: String.t,
        project_name: String.t,
        project_url: String.t,
        pull_name: String.t,
        pull_url: String.t,
        pull_status: String.t,
        review_state: String.t,
        reviewer: String.t,
        reviewers: list(String.t),
        requested_reviewer: String.t,
        has_been_merged: boolean(),
        has_been_closed: boolean()
    }

    defstruct action: nil,
              organization_name: nil,
              organization_url: nil,
              project_name: nil,
              project_url: nil,
              pull_name: nil,
              pull_url: nil,
              pull_status: nil,
              pull_owner: nil,
              review_state: nil,
              reviewer: nil,
              reviewers: [],
              requested_reviewer: nil,
              has_been_merged: false,
              has_been_closed: false
end
