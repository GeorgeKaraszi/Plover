defmodule PayloadParser.Payload do
    @moduledoc false

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
