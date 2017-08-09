defmodule Plover.Factory do
    @moduledoc false
    use ExMachina.Ecto, repo: Plover.Repo
    use Plover.UserFactory
    use Plover.GitHubProjectFactory
    use Plover.GitHubPullRequestFactory
    use Plover.GitHubReviewFactory
    use Plover.GithubPayloadFactory
end
