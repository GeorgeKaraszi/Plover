defmodule Plover.Commands.ErrorCommands do
    @moduledoc """
        Translates error messages into readable strings
    """

    @doc """
        Translates List of tuple error messages

        Returns
        - List of translated strings
    """
    def translate_errors(errors) do
        Enum.map(errors, fn {field, detail} ->
            to_string(field) <> " " <> render_details(detail)
        end)
    end

    @doc """
        Translates List of tuple error messages and joins them by a seperator

        Returns
        - A single string with joined messages
    """
    def translate_errors(errors, join_by: join_by) do
        errors
        |> translate_errors()
        |> Enum.join(join_by)
    end

    @doc """
        Takes a tuple and reduces it down to a single string message
    """
    def render_details({message, values}) do
        Enum.reduce(values, message,
            fn {k, v}, acc ->
                String.replace(acc, "#{k}", to_string(v))
            end
        )
    end
    def render_details({message}), do: message
    def render_details(message), do: message
end
