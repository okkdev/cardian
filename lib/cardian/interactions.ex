defmodule Cardian.Interactions do
  require Logger
  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias Cardian.{Builder, CardRegistry, Simulator}

  def deploy_commands() do
    {:ok, _} = Api.bulk_overwrite_global_application_commands(get_commands())
    IO.puts("Commands deployed! (It might take up to an hour to register...)")
  end

  def get_commands() do
    [
      card_command(),
      open_pack_command()
    ]
  end

  def card_command do
    %{
      name: "card",
      description: "Get Yu-Gi-Oh! Master Duel card info",
      options: [
        %{
          type: 3,
          name: "type",
          description: "Search a card by name"
        }
      ]
    }
  end

  def open_pack_command do
    %{
      name: "open",
      description: "Simulate opening Yu-Gi-Oh! Master Duel card packs",
      options: [
        %{
          type: 3,
          name: "pack",
          description: "Pack you want to open",
          autocomplete: true,
          required: true
        },
        %{
          type: 3,
          name: "amount",
          description: "How many packs",
          required: true,
          choices: Enum.map(1..10, &%{name: to_string(&1), value: to_string(&1)})
        }
      ]
    }
  end

  def handle(
        %Interaction{
          data: %{name: "card", options: [%{name: "name", value: query, focused: true}]}
        } = interaction
      ) do
    cards = CardRegistry.search_card(query)

    Api.create_interaction_response!(interaction, %{
      type: 8,
      data: Builder.build_autocomplete_choices(cards)
    })
  end

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
            #{inspect(c)}

            Built Message:
            #{inspect(msg)}
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

  def handle(
        %Interaction{
          data: %{name: "open", options: [%{name: "pack", value: query, focused: true}]}
        } = interaction
      ) do
    packs =
      query
      |> CardRegistry.search_set()
      |> Enum.filter(&Enum.member?([:normal_pack, :selection_pack, :secret_pack], &1.type))

    Api.create_interaction_response!(interaction, %{
      type: 8,
      data: Builder.build_autocomplete_choices(packs)
    })
  end

  def handle(
        %Interaction{
          data: %{
            name: "open",
            options: [
              %{name: "pack", value: pack},
              %{name: "amount", value: amount}
            ]
          }
        } = interaction
      ) do
    Api.create_interaction_response!(interaction, %{type: 5})

    case CardRegistry.get_set_by_id(pack) do
      [p | _] ->
        msg =
          p
          |> Simulator.open_pack(String.to_integer(amount))
          |> Builder.build_open_packs_message(p, String.to_integer(amount))

        case Api.edit_interaction_response(interaction, msg) do
          {:ok, _} ->
            :ok

          err ->
            Logger.error("""
            Found Pack:
            #{inspect(p)}

            Built Message:
            #{inspect(msg)}
            """)

            raise(inspect(err))
        end

      [] ->
        Api.edit_interaction_response!(
          interaction,
          Builder.build_user_message("`#{pack}` not found... :pensive:")
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

  def handle(_interaction), do: :noop
end
