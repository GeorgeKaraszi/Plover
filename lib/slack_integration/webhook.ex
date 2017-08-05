defmodule SlackIntegration.Webhook do
    @moduledoc """
        Integrates with slack by establishing communication with Slack's webhook API

        Remember to configure your webhook at config/config.exs:
            config :plover, SlackIntegration.Webhook, default_url: "https://hooks.slack.com/services/*/*/*"

        Credit:
         - Remigiusz Jackowski https://github.com/remiq/slack_webhook
    """

    @doc """
        Send message with default url
    """
    def send(message), do: __MODULE__.send(message, get_hook_url())

    @doc """
        Send and forget your message with default url (No response)
    """
    def async_send(message), do:  __MODULE__.async_send(message, get_hook_url())

    @doc """
    Sends the message to the given slack url
    """
    def send(message, url), do: HTTPoison.post(url, get_content(message))

    @doc """
    Sends the message to the given slack url (No Reponse)
    """
    def async_send(message, url), do: HTTPoison.post(url, get_content(message), [], [hackney: [:async]])

    defp get_hook_url do
      [default_url: url] =  Application.get_env(:plover, SlackIntegration.Webhook)
      url
    end
    defp get_content(message), do: """
        {
            "text": "#{message}"
        }
    """
end
