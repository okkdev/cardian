defmodule Cardian.Builder do
  import Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed
  alias Cardian.Struct.Card
  alias Cardian.CardRegistry
  alias Cardian.Api.Images

  @spell_trap_icons %{
    spell: "<:spell:948992874438070342>",
    trap: "<:trap:948992874438074428>",
    skill: "Skill"
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

  @hat_token "https://s3.lain.dev/ygo/hat-token.webp"

  @set_base_url "https://yugipedia.com/wiki/"

  def build_card_embed(%Card{} = card, format \\ :paper) do
    %Embed{}
    |> put_title(card.name)
    |> put_url(card.url)
    |> put_thumbnail(
      case Images.get_image_url(card) do
        {:ok, url} -> url
        _ -> card.image_url || @hat_token
      end
    )
    |> try_put_color(get_card_color(card))
    |> put_card_metadata(card, format)
    |> try_put_field("Pendulum Effect", card.pendulum_effect)
    |> put_card_description(card)
    |> try_put_field("Scale", card.scale, true)
    |> try_put_field("Arrows", card.arrows, true)
    |> put_monster_atk(card)
    |> try_put_field("Released in", build_sets(card, format))
    |> put_format_footer(format)
  end

  def build_art_message(%Card{} = card, image_url) when is_binary(image_url) do
    embed =
      %Embed{}
      |> put_title(card.name)
      |> put_url(card.url)
      |> put_image(image_url)
      |> try_put_color(get_card_color(card))
      |> put_ocg_footer(card)

    %{
      embeds: [
        embed
      ]
    }
  end

  defp put_format_footer(embed, :paper), do: put_footer(embed, "Format: Paper")
  defp put_format_footer(embed, :md), do: put_footer(embed, "Format: Master Duel")
  defp put_format_footer(embed, :dl), do: put_footer(embed, "Format: Duel Links")
  defp put_format_footer(embed, :sd), do: put_footer(embed, "Format: Speed Duel")

  defp put_ocg_footer(embed, %Card{ocg: true}) do
    embed
    |> put_footer("OCG Art")
  end

  defp put_ocg_footer(embed, %Card{ocg: false, id: card_id}) do
    if Images.ocg_available?(card_id) do
      embed
      |> put_footer("OCG art available")
    else
      embed
    end
  end

  def build_user_message(body) do
    %{
      content: body,
      flags: 64
    }
  end

  def build_ocg_kofi_reminder_embed(user_id) do
    embed =
      %Embed{}
      |> put_title("Unfortunately you don't have access to OCG art")
      |> put_description("""
      To gain access to the OCG art option, please donate to Cardian using the link below.
      https://ko-fi.com/okkkk

      This is your user id: `[#{user_id}]`
      Please include it (including the brackets) in your donation message!
      If done so, you should get access the OCG art option immediately.
      [More details here](https://ko-fi.com/post/Cardian-OCG-art-E1E4DXD7N)

      Thank you so much for considering to support Cardian!
      """)

    %{
      embeds: [
        embed
      ],
      flags: 64
    }
  end

  def build_autocomplete_choices(cards) do
    choices =
      cards
      |> Enum.take(25)
      |> Enum.map(&%{name: &1.name, value: &1.id})

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

  defp put_card_metadata(embed, %Card{type: :monster} = card, format) do
    level =
      case card.monster_type do
        :xyz -> "Rank"
        :link -> "Link"
        _ -> "Level"
      end

    attribute =
      case format do
        :paper ->
          "**Attribute**: #{@attribute_icons[card.attribute]}"

        :sd ->
          "**Attribute**: #{@attribute_icons[card.attribute]}"

        :md ->
          "**Attribute**: #{@attribute_icons[card.attribute]} #{put_card_rarity(card.rarity_md)}"

        :dl ->
          "**Attribute**: #{@attribute_icons[card.attribute]} #{put_card_rarity(card.rarity_dl)}"
      end

    put_description(
      embed,
      Enum.join(
        [
          attribute,
          "**#{level}**: #{card.level} **Type**: #{Enum.join([card.race | card.monster_types], "/")}",
          put_card_status(card, format)
        ],
        "\n"
      )
    )
  end

  defp put_card_metadata(embed, card, format) do
    type =
      case format do
        :paper ->
          "**Type**: #{@spell_trap_icons[card.type]} #{@card_type_icons[card.race]}"

        :sd ->
          "**Type**: #{@spell_trap_icons[card.type]} #{@card_type_icons[card.race]}"

        :md ->
          "**Type**: #{@spell_trap_icons[card.type]} #{@card_type_icons[card.race]} #{put_card_rarity(card.rarity_md)}"

        :dl ->
          "**Type**: #{@spell_trap_icons[card.type]} #{@card_type_icons[card.race]} #{put_card_rarity(card.rarity_dl)}"
      end

    put_description(
      embed,
      Enum.join(
        [
          type,
          put_card_status(card, format)
        ],
        "\n"
      )
    )
  end

  defp put_card_rarity(rarity) when is_map_key(@rarity_icons, rarity) do
    "**Rarity**: " <> @rarity_icons[rarity]
  end

  defp put_card_rarity(_), do: ""

  defp put_card_status(%Card{} = card, :paper) do
    """
    **TCG**: #{status_icon(card.status_tcg)}
    **OCG**: #{status_icon(card.status_ocg)}
    **Genesys**: #{card.genesys_points} Points
    """
  end

  defp put_card_status(%Card{} = card, :md) do
    "**Status**: #{status_icon(card.status_md)}"
  end

  defp put_card_status(%Card{} = card, :dl) do
    "**Status**: #{status_icon(card.status_dl)}"
  end

  defp put_card_status(%Card{} = _card, :sd) do
    ""
  end

  defp status_icon(status) when is_map_key(@status_icons, status) do
    @status_icons[status]
  end

  defp status_icon(_), do: "Unlimited"

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

  defp put_monster_atk(embed, %Card{type: :monster, monster_type: :link, atk: atk})
       when is_integer(atk) do
    put_field(embed, "ATK", "#{atk}", true)
  end

  defp put_monster_atk(embed, %Card{type: :monster, atk: atk, def: def})
       when is_integer(atk) and is_integer(def) do
    put_field(embed, "ATK / DEF", "#{atk} / #{def}", true)
  end

  defp put_monster_atk(embed, _card), do: embed

  defp build_sets(%Card{} = card, format)
       when format in [:paper, :sd] and
              is_list(card.sets_paper) and length(card.sets_paper) > 0 do
    card.sets_paper
    |> Enum.map(&"[#{&1}](#{@set_base_url}#{&1})")
    |> truncate_sets()
  end

  defp build_sets(%Card{} = card, :md) when is_list(card.sets_md) and length(card.sets_md) > 0 do
    card.sets_md
    |> Enum.flat_map(&CardRegistry.get_set_by_id(&1))
    |> Enum.map(
      &if &1.url do
        "[#{&1.name}](#{&1.url})"
      else
        &1.name
      end
    )
    |> truncate_sets()
  end

  defp build_sets(%Card{} = card, :dl) when is_list(card.sets_dl) and length(card.sets_dl) > 0 do
    card.sets_dl
    |> Enum.flat_map(&CardRegistry.get_set_by_id(&1))
    |> Enum.map(
      &if &1.url do
        "[#{&1.name}](#{&1.url})"
      else
        &1.name
      end
    )
    |> truncate_sets()
  end

  defp build_sets(_, _), do: "Unreleased"

  defp truncate_sets(sets) when is_list(sets) do
    {sets, rest} = Enum.split(sets, 5)

    case Enum.empty?(rest) do
      true ->
        sets
        |> Enum.join(", ")

      false ->
        sets
        |> Enum.join(", ")
        |> then(&"#{&1} and #{length(rest)} more...")
    end
  end

  defp try_put_color(embed, color) when is_integer(color) do
    put_color(embed, color)
  end

  defp try_put_color(embed, _color), do: embed

  defp get_card_color(%Card{type: :spell}), do: 1_941_108

  defp get_card_color(%Card{type: :trap}), do: 12_343_940

  defp get_card_color(%Card{type: :skill}), do: 26_316

  defp get_card_color(%Card{type: :monster, monster_type: type}) do
    case type do
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

  defp get_card_color(_), do: nil
end
