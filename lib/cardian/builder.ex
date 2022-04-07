defmodule Cardian.Builder do
  import Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed
  alias Cardian.Model.Card
  alias Cardian.CardRegistry

  @spell_trap_icons %{
    spell: "<:spell:948992874438070342>",
    trap: "<:trap:948992874438074428>"
  }

  @rarity_icons %{
    normal: "<:normalrare:948990033321414678>",
    rare: "<:rare:948990141786095667>",
    super: "<:superrare:948990076111712356>",
    ultra: "<:ultrarare:948990098920333332>"
  }

  @status_icons %{
    semilimited: "<:semilimited:948990692842156043>",
    limited: "<:limited:948990713272602695>",
    forbidden: "<:forbidden:948990744373387386>"
  }

  @attribute_icons %{
    "DARK" => "<:DARK:948992874400346152>",
    "DIVINE" => "<:DIVINE:948992874089947136>",
    "EARTH" => "<:EARTH:948992874442285096>",
    "FIRE" => "<:FIRE:948992874375176212>",
    "LIGHT" => "<:LIGHT:948992874396151879>",
    "WATER" => "<:WATER:948992874136096768>",
    "WIND" => "<:WIND:948992874123505775>"
  }

  @card_type_icons %{
    "Normal" => "",
    "Quick-Play" => "<:quickplay:948992874366771240>",
    "Ritual" => "<:ritual:948992874580680786>",
    "Field" => "<:field:948992874169630750>",
    "Equip" => "<:equip:948992874039623741>",
    "Continuous" => "<:continuous:948992874421305385>",
    "Counter" => "<:counter:948992874400321617>"
  }

  def build_card_message(%Card{} = card) do
    embed =
      %Embed{}
      |> put_title(card.name)
      |> put_url(card.url)
      |> put_thumbnail(card.image_url)
      |> try_put_color(get_card_color(card))
      |> put_card_metadata(card)
      |> try_put_field("Pendulum Effect", card.pendulum_effect)
      |> put_card_description(card)
      |> try_put_field("Scale", card.scale, true)
      |> try_put_field("Arrows", card.arrows, true)
      |> put_monster_atk(card)
      |> try_put_field("Obtainable from", build_sets(card.sets))

    %{
      embeds: [
        embed
      ]
    }
  end

  def build_art_message(%Card{} = card, image_url) when is_binary(image_url) do
    embed =
      %Embed{}
      |> put_title(card.name)
      |> put_url(card.url)
      |> put_image(image_url)
      |> try_put_color(get_card_color(card))

    %{
      embeds: [
        embed
      ]
    }
  end

  def build_user_message(body) do
    %{
      content: body,
      flags: 64
    }
  end

  def build_autocomplete_choices(cards) do
    choices =
      cards
      |> Stream.take(25)
      |> Stream.map(&%{name: &1.name, value: &1.id})
      |> Enum.to_list()

    %{
      choices: choices
    }
  end

  defp try_put_field(embed, title, content, inline \\ nil)

  defp try_put_field(embed, title, content, inline)
       when is_binary(content) or is_integer(content) do
    put_field(embed, title, content, inline)
  end

  defp try_put_field(embed, _title, _content, _inline), do: embed

  defp put_card_metadata(embed, %Card{type: :monster} = card) do
    level =
      case card.monster_type do
        :xyz -> "Rank"
        :link -> "Link"
        _ -> "Level"
      end

    put_description(
      embed,
      Enum.join(
        [
          "**Attribute**: #{@attribute_icons[card.attribute]} #{put_card_rarity(card.rarity)}",
          "**#{level}**: #{card.level} **Type**: #{Enum.join([card.race | card.monster_types], "/")}",
          "**Status**: #{@status_icons[card.status]}"
        ],
        "\n"
      )
    )
  end

  defp put_card_metadata(embed, card) do
    put_description(
      embed,
      Enum.join(
        [
          "**Type**: #{@spell_trap_icons[card.type]} #{@card_type_icons[card.race]} #{put_card_rarity(card.rarity)}",
          "**Status**: #{@status_icons[card.status]}"
        ],
        "\n"
      )
    )
  end

  defp put_card_rarity(rarity) when is_map_key(@rarity_icons, rarity) do
    "**Rarity**: " <> @rarity_icons[rarity]
  end

  defp put_card_rarity(_), do: ""

  defp put_card_description(embed, %Card{type: :monster} = card) do
    if Enum.member?(card.monster_types, "Normal") do
      put_field(embed, "Flavor Text", card.description)
    else
      put_field(embed, "Monster Effect", card.description)
    end
  end

  defp put_card_description(embed, card) do
    put_field(embed, "Effect", card.description)
  end

  defp put_monster_atk(embed, %Card{type: :monster, monster_type: :link} = card) do
    put_field(embed, "ATK", "#{card.atk}", true)
  end

  defp put_monster_atk(embed, %Card{type: :monster} = card) do
    put_field(embed, "ATK / DEF", "#{card.atk} / #{card.def}", true)
  end

  defp put_monster_atk(embed, _card), do: embed

  defp build_sets(sets) when is_list(sets) and length(sets) > 0 do
    sets
    |> Stream.flat_map(&CardRegistry.get_set_by_id(&1))
    |> Stream.map(
      &if &1.url do
        "[#{&1.name}](#{&1.url})"
      else
        &1.name
      end
    )
    |> Enum.join("\n")
  end

  defp build_sets(_), do: "Unobtainable"

  defp try_put_color(embed, color) when is_integer(color) do
    put_color(embed, color)
  end

  defp try_put_color(embed, _color), do: embed

  defp get_card_color(%Card{type: :spell}), do: 1_941_108

  defp get_card_color(%Card{type: :trap}), do: 12_343_940

  defp get_card_color(%Card{type: :monster} = card) do
    case card.monster_type do
      :normal ->
        14_995_823

      :effect ->
        14_847_836

      :fusion ->
        13_069_544

      :ritual ->
        7_119_592

      :synchro ->
        15_132_390

      :xyz ->
        1_842_203

      :link ->
        3_502_533

      :pendulum ->
        4_251_856

      _ ->
        nil
    end
  end
end
