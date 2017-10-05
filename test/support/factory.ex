defmodule Plover.Factory do
    @moduledoc false
    use ExMachina.Ecto, repo: Plover.Repo
    use Plover.UserFactory
    use Plover.GithubPayloadFactory
    use Plover.SlackMessageFactory
    use Plover.SlackStateFactory
end
