# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Plover.Repo.insert!(%Plover.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

if Mix.env == :dev do
    Plover.Factory.insert(:user, github_login: "GeorgeKaraszi", slack_login: "@george")
    Plover.Factory.insert(:user, github_login: "ploverreview", slack_login: "@pr_review")
    Plover.Factory.insert(:user, github_login: "plover-reviewer-2", slack_login: "@pr_review2")
end
