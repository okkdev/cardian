defmodule Cardian.Interactions do
  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias Cardian.Api.Masterduelmeta
  alias Cardian.Builder

  def initialize_interactions() do
    card_command()
  end

  def card_command do
    command = %{
      name: "card",
      description: "Get Yu-Gi-Oh! Master Duel card info",
      options: [
        %{
          type: 3,
          name: "name",
          description: "Search a card by name (autocomplete after 3 characters)",
          autocomplete: true,
          required: true
        }
      ]
    }

    Api.create_guild_application_command(
      %Nostrum.Struct.Guild{id: 582_319_286_295_724_035}.id,
      command
    )
  end

  def handle(
        %Interaction{
          data: %{name: "card", options: [%{name: "name", value: query, focused: true}]}
        } = interaction
      ) do
    cards =
      if String.length(query) > 3 do
        Masterduelmeta.search_card(query)
      else
        []
      end

    Api.create_interaction_response!(interaction, %{
      type: 8,
      data: Builder.build_autocomplete_choices(cards)
    })
  end

  def handle(
        %Interaction{data: %{name: "card", options: [%{name: "name", value: card}]}} = interaction
      ) do
    Api.create_interaction_response!(interaction, %{type: 5})

    case Masterduelmeta.get_card(card) do
      [c | _] ->
        Api.edit_interaction_response!(interaction, Builder.build_card_message(c))

      [] ->
        Api.edit_interaction_response!(
          interaction,
          Builder.build_user_message("Card not found :pensive:")
        )
    end
  end

  def handle(_interaction) do
    :noop
  end
end
