defmodule PloverWeb.AccountController do
    use PloverWeb, :controller
    plug PloverWeb.Plugs.RequireAuth

    alias Plover.{Account, Slack}

    def show(conn, _params) do
        if required_information?(conn.assigns.user) do
            render conn, "show.html"
        else
            redirect(conn, to: account_path(conn, :edit))
        end
    end

    def update(conn, %{"user" => params}) do
        case Account.update_user(conn.assigns.user, params) do
            {:ok, _user} ->
                conn
                |> put_flash(:info, "Successfully registered your slack login")
                |> redirect(to: account_path(conn, :show))
            {:error, changeset} ->
                render(conn, "edit.html", changeset: changeset)
        end
    end

    def slack_user_check(conn, %{"user" => params}) do
        %{"slack_login" => slack_login} = params
        exists = Slack.user_exists?(slack_login)

        conn
        |> put_status(:ok)
        |> json(%{exists: exists})
    end

    def edit(conn, _params) do
        changeset = Account.changeset(conn.assigns.user)
        render conn, "edit.html", changeset: changeset
    end

    defp required_information?(%Account.User{slack_login: slack, github_login: github}) do
        slack != nil && github != nil
    end
end
