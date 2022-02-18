defmodule Cardian.Builder do
  import Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed
  alias Cardian.Api.Masterduelmeta

  # TODO: Rewrite generically, create datatypes

  def build_card_message(card) do
    case card["type"] do
      "Monster" -> build_monster_message(card)
      "Spell" -> build_spelltrap_message(card)
      "Trap" -> build_spelltrap_message(card)
      _ -> build_user_message("Card type \"#{card["type"]}\" not supported yet :pensive:")
    end
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
      |> Enum.map(&%{name: &1["name"], value: &1["_id"]})

    %{
      choices: choices
    }
  end

  defp build_spelltrap_message(card) do
    embed =
      %Embed{}
      |> put_title(card["name"])
      |> put_url(Masterduelmeta.get_card_link(card["name"]))
      |> put_thumbnail(Masterduelmeta.get_image(card["_id"]))
      |> put_color(if card["type"] == "Spell", do: 1_941_108, else: 12_343_940)
      |> put_field("Type", card["race"], true)
      |> put_field("Effect", card["description"])
      |> put_field("Rarity", "**#{card["rarity"]}**", true)
      |> put_field(
        "Status",
        if(card["banStatus"], do: card["banStatus"], else: "Unlimited"),
        true
      )
      |> put_field("Obtain", put_sets(card["obtain"]), true)

    %{
      embeds: [
        embed
      ]
    }
  end

  defp build_monster_message(card) do
    monster_type = get_monster_type(card["monsterType"])

    embed =
      %Embed{}
      |> put_title(card["name"])
      |> put_url(Masterduelmeta.get_card_link(card["name"]))
      |> put_thumbnail(Masterduelmeta.get_image(card["_id"]))
      |> put_color(get_monster_color(monster_type))
      |> put_field("Attribute", card["attribute"], true)
      |> put_monster_fields(card, monster_type)
      |> put_field("Rarity", "**#{card["rarity"]}**", true)
      |> put_field(
        "Status",
        if(card["banStatus"], do: card["banStatus"], else: "Unlimited"),
        true
      )
      |> put_field("Obtain", put_sets(card["obtain"]), true)

    %{
      embeds: [
        embed
      ]
    }
  end

  defp put_monster_fields(embed, card, :link) do
    embed
    |> put_field("Link Rating", card["linkRating"], true)
    |> put_field("Type", Enum.join([card["race"] | card["monsterType"]], " / "), true)
    |> put_field("Monster Effect", card["description"])
    |> put_field("ATK", card["atk"], true)
    |> put_field("Link Arrows", put_link_arrows(card["linkArrows"]), true)
    |> put_field("\u200b", "\u200b", true)
  end

  defp put_monster_fields(embed, card, :pendulum) do
    embed
    |> put_field("Level", card["level"], true)
    |> put_field("Type", Enum.join([card["race"] | card["monsterType"]], " / "), true)
    |> put_field("Description", card["description"])
    |> put_field("ATK", card["atk"], true)
    |> put_field("DEF", card["def"], true)
    |> put_field("⬅️Scale➡️", card["scale"], true)
  end

  defp put_monster_fields(embed, card, type) do
    embed
    |> put_field(if(type == :xyz, do: "Rank", else: "Level"), card["level"], true)
    |> put_field("Type", Enum.join([card["race"] | card["monsterType"]], " / "), true)
    |> put_field(
      if(type == :normal, do: "Description", else: "Monster Effect"),
      card["description"]
    )
    |> put_field("ATK", card["atk"], true)
    |> put_field("DEF", card["def"], true)
    |> put_field("\u200b", "\u200b", true)
  end

  defp put_link_arrows(arrows) do
    mapping = %{
      "Top-Left" => "↖️",
      "Top" => "⬆️",
      "Top-Right" => "↗️",
      "Left" => "⬅️",
      "Right" => "➡️",
      "Bottom-Left" => "↙️",
      "Bottom" => "⬇️",
      "Bottom-Right" => "↘️"
    }

    arrows
    |> Enum.map(&mapping[&1])
    |> Enum.join()
  end

  defp put_sets(sets) when length(sets) > 0 do
    sets
    |> Enum.map(& &1["source"]["_id"])
    |> Masterduelmeta.get_sets_by_id()
    |> Enum.map(&put_set_link/1)
    |> Enum.join()
  end

  defp put_sets(_) do
    "No Packs"
  end

  defp put_set_link(set) do
    case set["linkedArticle"] do
      %{"url" => url} ->
        "[#{set["name"]}](#{Masterduelmeta.get_set_link(url)})\n"

      _ ->
        "#{set["name"]}\n"
    end
  end

  defp get_monster_type(type) do
    case hd(type) do
      "Synchro" -> :synchro
      "Effect" -> :effect
      "Normal" -> :normal
      "Xyz" -> :xyz
      "Fusion" -> :fusion
      "Pendulum" -> :pendulum
      "Link" -> :link
      "Ritual" -> :ritual
      _ -> nil
    end
  end

  defp get_monster_color(:synchro) do
    15_132_390
  end

  defp get_monster_color(:fusion) do
    10_520_247
  end

  defp get_monster_color(:ritual) do
    10_335_692
  end

  defp get_monster_color(:link) do
    139
  end

  defp get_monster_color(:normal) do
    16_639_626
  end

  defp get_monster_color(:xyz) do
    0
  end

  defp get_monster_color(_) do
    13_665_078
  end
end
