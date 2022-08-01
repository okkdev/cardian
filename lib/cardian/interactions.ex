defmodule Cardian.Interactions do
  require Logger
  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias Cardian.{Builder, CardRegistry}

  def deploy_commands() do
    {:ok, _} = Api.bulk_overwrite_global_application_commands(get_commands())
    IO.puts("Commands deployed! (It might take up to an hour to register...)")
  end

  def get_commands() do
    [
      card_command(),
      art_command()
    ]
  end

  def card_command do
    %{
      name: "card",
      description: "Get Yu-Gi-Oh! Master Duel card info",
      options: [
        %{
          type: 3,
          name: "name",
          description: "Search a card by name",
          autocomplete: true,
          required: true
        }
      ]
    }
  end

  def art_command do
    %{
      name: "art",
      description: "Get Yu-Gi-Oh! Master Duel card art",
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

  # Handle search autocompletion
  def handle(
        %Interaction{
          data: %{name: command_name, options: [%{name: "name", value: query, focused: true} | _]}
        } = interaction
      )
      when command_name in ["card", "art"] do
    cards = CardRegistry.search_card(query)

    Api.create_interaction_response!(interaction, %{
      type: 8,
      data: Builder.build_autocomplete_choices(cards)
    })
  end

  # Handle card command
  def handle(
        %Interaction{data: %{name: "card", options: [%{name: "name", value: card}]}} = interaction
      ) do
    Api.create_interaction_response!(interaction, %{type: 5})

    case CardRegistry.get_card(card) do
      [c | _] ->
        msg = Builder.build_card_message(c)

        case Api.edit_interaction_response(interaction, msg) do
          {:ok, _} ->
            :ok

          err ->
            Logger.error("""
            Card name/id:
            #{card}

            Found Card:
            #{inspect(c, pretty: true)}

            Built Message:
            #{inspect(msg, pretty: true)}
            """)

            raise(inspect(err))
        end

      [] ->
        Api.edit_interaction_response!(
          interaction,
          Builder.build_user_message("`#{card}` not found... :pensive:")
        )
    end
  rescue
    err ->
      Logger.error(Exception.format(:error, err, __STACKTRACE__))

      Api.edit_interaction_response!(
        interaction,
        Builder.build_user_message("Something went wrong... :pensive:")
      )
  end

  # Handle premium ocg requests
  def handle(
        %Interaction{
          data: %{
            name: "art",
            options: [%{name: "name"}, %{name: "ocg", value: true} | _]
          },
          user: %{id: user_id}
        } = interaction
      ) do
    if Cardian.Api.Bonk.valid_user?(user_id) do
      handle_art(interaction, true)
    else
      Api.create_interaction_response!(
        interaction,
        %{
          type: 4,
          data: Builder.build_ocg_kofi_reminder_embed(user_id)
        }
      )
    end
  end

  # Handle regular art calls
  def handle(%Interaction{data: %{name: "art"}} = interaction) do
    handle_art(interaction, false)
  end

  def handle(interaction) do
    Logger.error("Unknown command: #{inspect(interaction, pretty: true)}")

    Api.create_interaction_response!(
      interaction,
      %{
        type: 4,
        data: Builder.build_user_message("Something went wrong... :pensive:")
      }
    )
  end

  defp handle_art(
         %Interaction{
           data: %{
             name: "art",
             options: [%{name: "name", value: card} | _]
           }
         } = interaction,
         ocg
       ) do
    Api.create_interaction_response!(interaction, %{type: 5})

    case CardRegistry.get_card(card) do
      [c | _] ->
        c = %{c | ocg: ocg}

        case Cardian.Api.Images.get_image_url(c) do
          {:ok, image_url} ->
            msg = Builder.build_art_message(c, image_url)

            case Api.edit_interaction_response(interaction, msg) do
              {:ok, _} ->
                :ok

              err ->
                Logger.error("""
                Card name/id:
                #{card}

                Found Card:
                #{inspect(c, pretty: true)}

                Built Message:
                #{inspect(msg, pretty: true)}
                """)

                raise(inspect(err))
            end

          _ ->
            Api.edit_interaction_response!(
              interaction,
              Builder.build_user_message(
                "#{if c.ocg, do: "OCG "}Art for `#{c.name}` not found... :pensive:"
              )
            )
        end

      [] ->
        Api.edit_interaction_response!(
          interaction,
          Builder.build_user_message("`#{card}` not found... :pensive:")
        )
    end
  rescue
    err ->
      Logger.error(Exception.format(:error, err, __STACKTRACE__))

      Api.edit_interaction_response!(
        interaction,
        Builder.build_user_message("Something went wrong... :pensive:")
      )
  end
end
