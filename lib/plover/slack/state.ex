defmodule Plover.Slack.State do
    @moduledoc false

    @type t :: %Plover.Slack.State{
        message_type: String.t,
        pull_url: String.t,
        channel_id: String.t,
        targeted_users: String.t
    }

    defstruct [
        message_type: nil,
        pull_url: nil,
        channel_id: nil,
        targeted_users: nil
    ]

end
