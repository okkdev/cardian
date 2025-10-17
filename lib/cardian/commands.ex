defmodule Cardian.Commands do
  alias Nostrum.Api

  def deploy() do
    {:ok, _} = get_commands() |> Api.ApplicationCommand.bulk_overwrite_global_commands()

    IO.puts("Commands deployed! (It might take up to an hour to register...)")
  end

  defp get_commands() do
    [
      card_command(),
      parse_card_command(),
      art_command()
    ]
  end

  defp card_command do
    %{
      name: "card",
      description: "Get Yu-Gi-Oh! card info",
      integration_types: [0, 1],
      contexts: [0, 1, 2],
      options: [
        %{
          type: 3,
          name: "name",
          description: "Search a card by name",
          autocomplete: true,
          required: true
        },
        %{
          type: 3,
          name: "format",
          description: "Which format of the card game (remembers your last choice)",
          choices: [
            %{
              name: "Paper (TCG, OCG, Genesys)",
              value: "paper"
            },
            %{
              name: "Master Duel",
              value: "md"
            },
            %{
              name: "Duel Links",
              value: "dl"
            }
          ]
        }
      ]
    }
  end

  defp parse_card_command do
    %{
      type: 3,
      name: "Embed cards",
      integration_types: [0, 1],
      contexts: [0, 1, 2]
    }
  end

  defp art_command do
    %{
      name: "art",
      description: "Get Yu-Gi-Oh! card art",
      integration_types: [0, 1],
      contexts: [0, 1, 2],
      options: [
        %{
          type: 3,
          name: "name",
          description: "Search a card by name",
          autocomplete: true,
          required: true
        },
        %{
          type: 5,
          name: "ocg",
          description: "Show the OCG art (not available for all cards)"
        }
      ]
    }
  end
end
