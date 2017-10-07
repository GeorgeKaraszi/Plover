defmodule Plover.Slack.State do
    @moduledoc false

    defstruct [
        message_type: nil,
        pull_url: nil,
        channel_id: nil,
        targeted_users: nil
    ]

end
