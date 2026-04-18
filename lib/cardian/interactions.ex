defmodule Cardian.Interactions do
  require Logger
  require OpenTelemetry.Tracer, as: Tracer
  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias Cardian.{Builder, CardRegistry, Metrics}
  alias Cardian.Api.Images
  alias Cardian.Configs.UserConfig
  alias Cardian.UserConfigs

  # Handle search autocompletion
  def handle(
        %Interaction{
          data: %{name: command_name, options: [%{name: "name", value: query, focused: true} | _]}
        } = interaction
      )
      when command_name in ["card", "art"] do
    Tracer.with_span "interaction.autocomplete",
      attributes: %{"command" => command_name, "query" => query} do
      cards =
        Tracer.with_span "card_registry.search" do
          CardRegistry.search_card(query)
        end

      Tracer.set_attribute("results", length(cards))

      choices = Builder.build_autocomplete_choices(cards)

      Tracer.with_span "discord.create_response" do
        Api.Interaction.create_response(interaction, %{
          type: 8,
          data: choices
        })
      end
    end
  end

  # Handle card command
  def handle(
        %Interaction{
          data: %{
            name: "card",
            options: [%{name: "name", value: card} | _] = options
          },
          user: %{id: user_id}
        } = interaction
      ) do
    Tracer.with_span "interaction.card",
      attributes: %{"query" => card, "user_id" => to_string(user_id)} do
      defer_task = Task.async(fn -> Api.Interaction.create_response(interaction, %{type: 5}) end)

      case Tracer.with_span("card_registry.lookup", do: CardRegistry.get_card(card)) do
        [c | _] ->
          Metrics.count_card_request(c.name, "card")
          Tracer.set_attribute("card", c.name)
          format = resolve_format(c.type, options, user_id)
          Tracer.set_attribute("format", to_string(format))

          thumbnail_url =
            Tracer.with_span "images.get_url" do
              case Images.get_image_url(c) do
                {:ok, url} -> url
                _ -> nil
              end
            end

          msg = %{
            embeds: [
              Builder.build_card_embed(c, format, thumbnail_url)
            ]
          }

          Task.await(defer_task)
          edit_response(interaction, msg)

        [] ->
          Tracer.set_attribute("card_found", false)

          Task.await(defer_task)

          Api.Interaction.edit_response(
            interaction,
            Builder.build_user_message("`#{card}` not found... :pensive:")
          )
      end
    end
  end

  # Handle right click on message to parse cards in angle brackets < >
  def handle(
        %Interaction{
          data: %{
            name: "Embed cards",
            resolved: %{
              messages: messages
            }
          }
        } = interaction
      ) do
    Tracer.with_span "interaction.embed_cards" do
      [message | _] =
        messages
        |> Map.values()

      card_refs = Cardian.Parser.parse(message.content)

      Tracer.set_attribute("card_count", length(card_refs))

      case card_refs do
        [] ->
          Api.Interaction.create_response(
            interaction,
            %{
              type: 4,
              data:
                Builder.build_user_message(
                  "No card names found. Use `<card name>` or `[card name]` for info, `a[card name]` for art."
                )
            }
          )

        card_refs ->
          defer_task =
            Task.async(fn -> Api.Interaction.create_response(interaction, %{type: 5}) end)

          resolved =
            Tracer.with_span "card_registry.lookup_batch" do
              card_refs
              |> Enum.map(fn {type, name} ->
                case CardRegistry.get_card(name) do
                  [c | _] -> {type, c}
                  [] -> nil
                end
              end)
              |> Enum.filter(&(not is_nil(&1)))
              |> Enum.uniq_by(fn {type, card} -> {type, card.name} end)
              |> Enum.take(10)
            end

          Tracer.set_attribute("cards_found", length(resolved))

          Task.await(defer_task)

          if Enum.empty?(resolved) do
            Api.Interaction.edit_response(
              interaction,
              Builder.build_user_message("Cards not found... :pensive:")
            )
          else
            Enum.each(resolved, fn {type, card} ->
              Metrics.count_card_request(card.name, "embed_#{type}")
            end)

            Api.Interaction.delete_response(interaction)

            embeds =
              Tracer.with_span "images.get_urls_batch" do
                resolved
                |> Task.async_stream(fn {type, card} ->
                  case Images.get_image_url(card) do
                    {:ok, url} ->
                      case type do
                        :card -> Builder.build_card_embed(card, :paper, url)
                        :art -> Builder.build_art_embed(card, url)
                      end

                    _ ->
                      case type do
                        :card -> Builder.build_card_embed(card, :paper, nil)
                        :art -> nil
                      end
                  end
                end)
                |> Enum.map(fn {:ok, embed} -> embed end)
                |> Enum.filter(&(not is_nil(&1)))
              end

            Tracer.with_span "discord.create_message" do
              Api.Message.create(
                message.channel_id,
                embeds: embeds,
                message_reference: %{message_id: message.id}
              )
            end
          end
      end
    end
  end

  # Handle premium ocg art requests
  def handle(
        %Interaction{
          data: %{
            name: "art",
            options: [%{name: "name"}, %{name: "ocg", value: true} | _]
          },
          user: %{id: user_id}
        } = interaction
      ) do
    Tracer.with_span "interaction.art",
      attributes: %{"ocg" => true, "user_id" => to_string(user_id)} do
      if Cardian.Api.Bonk.valid_user?(user_id) do
        handle_art(interaction, true)
      else
        Tracer.set_attribute("ocg_denied", true)

        Api.Interaction.create_response(
          interaction,
          %{
            type: 4,
            data: Builder.build_ocg_kofi_reminder_embed(user_id)
          }
        )
      end
    end
  end

  # Handle regular art calls
  def handle(%Interaction{data: %{name: "art"}} = interaction) do
    Tracer.with_span "interaction.art", attributes: %{"ocg" => false} do
      handle_art(interaction, false)
    end
  end

  def handle(interaction) do
    Tracer.with_span "interaction.unknown" do
      Logger.error("Unknown command: #{inspect(interaction, pretty: true)}")

      Api.Interaction.create_response(
        interaction,
        %{
          type: 4,
          data: Builder.build_user_message("Something went wrong... :pensive:")
        }
      )
    end
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
    Tracer.set_attribute("query", card)
    defer_task = Task.async(fn -> Api.Interaction.create_response(interaction, %{type: 5}) end)

    case Tracer.with_span("card_registry.lookup", do: CardRegistry.get_card(card)) do
      [c | _] ->
        Metrics.count_card_request(c.name, "art")
        Tracer.set_attribute("card", c.name)
        c = %{c | ocg: ocg}

        ocg_task =
          if not ocg, do: Task.async(fn -> Images.ocg_available?(c.id) end)

        case Tracer.with_span("images.get_url", do: Images.get_image_url(c)) do
          {:ok, image_url} ->
            ocg_available = if ocg_task, do: Task.await(ocg_task, 3000), else: false
            msg = Builder.build_art_message(c, image_url, ocg_available)

            Task.await(defer_task)
            edit_response(interaction, msg)

          _ ->
            Tracer.add_event("image_not_found", %{"card" => c.name})
            if ocg_task, do: Task.shutdown(ocg_task, :brutal_kill)

            Task.await(defer_task)

            Api.Interaction.edit_response(
              interaction,
              Builder.build_user_message(
                "#{if c.ocg, do: "OCG "}Art for `#{c.name}` not found... :pensive:"
              )
            )
        end

      [] ->
        Tracer.set_attribute("card_found", false)

        Task.await(defer_task)

        Api.Interaction.edit_response(
          interaction,
          Builder.build_user_message("`#{card}` not found... :pensive:")
        )
    end
  end

  @error_message """
  Something went wrong... :pensive:
  If this issue persists, report it on the [Cardian Support Server](<https://discord.gg/GDt8p2Jyrn>).
  """

  defp edit_response(interaction, msg) do
    Tracer.with_span "discord.edit_response" do
      case Api.Interaction.edit_response(interaction, msg) do
        {:ok, _} = result ->
          result

        {:error, reason} ->
          Tracer.set_status(:error, inspect(reason))
          Logger.error("edit_response failed: #{inspect(reason)}")
          Api.Interaction.edit_response(interaction, Builder.build_user_message(@error_message))
      end
    end
  end

  defp resolve_format(:skill, _options, _user_id), do: :sd

  defp resolve_format(_type, options, user_id) do
    case Enum.find(options, &(&1.name == "format")) do
      %{value: v} when v in ["paper", "md", "dl"] ->
        format = String.to_existing_atom(v)
        UserConfigs.create_or_update_config(%{discord_id: user_id, format: format})
        format

      _ ->
        case UserConfigs.get_config_by_discord_id(user_id) do
          %UserConfig{format: f} -> f
          _ -> :paper
        end
    end
  end
end
