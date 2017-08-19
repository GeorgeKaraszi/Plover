defmodule Integration.Github.Payload do
    @moduledoc false

    defstruct organization_name: nil,
              organization_url: nil,
              project_name: nil,
              project_url: nil,
              pull_name: nil,
              pull_url: nil,
              pull_status: nil,
              review_state: nil,
              reviewer: nil,
              reviewers: []
end
