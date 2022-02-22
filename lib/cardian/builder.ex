defmodule Cardian.Builder do
  import Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed
  alias Cardian.Model.Card

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

  def build_user_message(body) do
    %{
      content: body,
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

  defp try_put_field(embed, _title, _content, _inline) do
    embed
  end

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
          "**Attribute**: #{card.attribute} **Rarity**: #{card.rarity}",
          "**#{level}**: #{card.level} **Type**: #{Enum.join([card.race | card.monster_types], "/")}",
          "**Status**: #{card.status}"
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
          "**Type**: #{card.race} **Rarity**: #{card.rarity}",
          "**Status**: #{card.status}"
        ],
        "\n"
      )
    )
  end

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

  defp put_monster_atk(embed, _card) do
    embed
  end

  defp build_sets(sets) when is_list(sets) and length(sets) > 0 do
    Enum.map_join(
      sets,
      "\n",
      &if &1.url do
        "[#{&1.name}](#{&1.url})"
      else
        &1.name
      end
    )
  end

  defp build_sets(_) do
    "No packs"
  end

  defp try_put_color(embed, color) when is_integer(color) do
    put_color(embed, color)
  end

  defp try_put_color(embed, _color) do
    embed
  end

  defp get_card_color(%Card{type: :spell}) do
    1_941_108
  end

  defp get_card_color(%Card{type: :trap}) do
    12_343_940
  end

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
