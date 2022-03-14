defmodule Cardian.Api.Masterduelmeta do
  alias Cardian.Model.{Card, Set}

  @url "https://www.masterduelmeta.com/api/v1"

  @rarity_mapping %{
    "N" => "<:normalrare:948990033321414678>",
    "R" => "<:rare:948990141786095667>",
    "SR" => "<:superrare:948990076111712356>",
    "UR" => "<:ultrarare:948990098920333332>"
  }

  @status_mapping %{
    "Limited 2" => "<:semilimited:948990692842156043>",
    "Limited 1" => "<:limited:948990713272602695>",
    "Forbidden" => "<:forbidden:948990744373387386>"
  }

  @arrow_mapping %{
    "Top-Left" => "↖️",
    "Top" => "⬆️",
    "Top-Right" => "↗️",
    "Left" => "⬅️",
    "Right" => "➡️",
    "Bottom-Left" => "↙️",
    "Bottom" => "⬇️",
    "Bottom-Right" => "↘️"
  }

  @attribute_mapping %{
    "DARK" => "<:DARK:948992874400346152>",
    "DIVINE" => "<:DIVINE:948992874089947136>",
    "EARTH" => "<:EARTH:948992874442285096>",
    "FIRE" => "<:FIRE:948992874375176212>",
    "LIGHT" => "<:LIGHT:948992874396151879>",
    "WATER" => "<:WATER:948992874136096768>",
    "WIND" => "<:WIND:948992874123505775>"
  }

  @card_type_mapping %{
    "Normal" => "<:normal:949015950378811412>",
    "Quick-Play" => "<:quickplay:948992874366771240>",
    "Ritual" => "<:ritual:948992874580680786>",
    "Field" => "<:field:948992874169630750>",
    "Equip" => "<:equip:948992874039623741>",
    "Continuous" => "<:continuous:948992874421305385>",
    "Counter" => "<:counter:948992874400321617>"
  }

  def get_all_cards() do
    pages = ceil(get_card_amount() / 3000)

    1..pages
    |> Stream.flat_map(fn page ->
      url =
        "#{@url}/cards?limit=3000&page=#{page}"
        |> URI.encode()

      Finch.build(:get, url)
      |> Finch.request(MyFinch)
      |> handle_response()
    end)
    |> Stream.filter(&(&1["alternateArt"] != true))
    |> Stream.map(&cast_card/1)
    |> Enum.to_list()
  end

  def get_card_amount() do
    url =
      (@url <> "/cards?collectionCount=true")
      |> URI.encode()

    Finch.build(:get, url)
    |> Finch.request(MyFinch)
    |> case do
      {:ok, res} ->
        String.to_integer(res.body)

      {:error, reason} ->
        raise(reason)
    end
  end

  def get_all_sets() do
    pages = ceil(get_sets_amount() / 3000)

    1..pages
    |> Stream.flat_map(fn page ->
      url =
        "#{@url}/sets?limit=3000&page=#{page}"
        |> URI.encode()

      Finch.build(:get, url)
      |> Finch.request(MyFinch)
      |> handle_response()
    end)
    |> Stream.map(&cast_set/1)
    |> Enum.to_list()
  end

  def get_sets_amount() do
    url =
      (@url <> "/sets?collectionCount=true")
      |> URI.encode()

    Finch.build(:get, url)
    |> Finch.request(MyFinch)
    |> case do
      {:ok, res} ->
        String.to_integer(res.body)

      {:error, reason} ->
        raise(reason)
    end
  end

  defp get_image(card_id) when is_binary(card_id) do
    "https://imgserv.duellinksmeta.com/v2/mdm/card/#{card_id}?portrait=true"
    |> URI.encode()
  end

  defp get_card_link(card_name) when is_binary(card_name) do
    ("https://www.masterduelmeta.com/cards/" <> card_name)
    |> URI.encode()
  end

  defp get_set_link(url_path) when is_binary(url_path) do
    ("https://www.masterduelmeta.com/articles" <> url_path)
    |> URI.encode()
  end

  defp get_set_link(_), do: nil

  defp handle_response(resp) do
    case resp do
      {:ok, res} ->
        Jason.decode!(res.body)

      {:error, reason} ->
        raise(reason)
    end
  end

  defp cast_card(resp) do
    {pendulum_effect, description} = parse_effects(resp["description"])

    %Card{
      id: resp["_id"],
      type: get_card_type(resp["type"]),
      race: parse_card_race(resp["race"]),
      monster_type: get_monster_type(resp["monsterType"]),
      monster_types: resp["monsterType"],
      attribute: @attribute_mapping[resp["attribute"]],
      level: resp["level"] || resp["linkRating"],
      name: resp["name"],
      description: description,
      pendulum_effect: pendulum_effect,
      atk: resp["atk"],
      def: resp["def"],
      scale: resp["scale"],
      arrows: parse_link_arrows(resp["linkArrows"]),
      status: @status_mapping[resp["banStatus"]] || "Unlimited",
      rarity: @rarity_mapping[resp["rarity"]],
      image_url: get_image(resp["_id"]),
      url: get_card_link(resp["name"]),
      sets: Enum.map(resp["obtain"], & &1["source"]["_id"])
    }
  end

  defp cast_set(resp) do
    %Set{
      id: resp["_id"],
      name: resp["name"],
      url: get_set_link(resp["linkedArticle"]["url"])
    }
  end

  defp parse_effects("[ Pendulum Effect ]" <> description) do
    [pendulum_effect, rest] = String.split(description, ["---", "[ "], parts: 2)
    [_, description] = String.split(rest, "]", parts: 2)

    {
      String.trim(pendulum_effect),
      String.trim(description)
    }
  end

  defp parse_effects(description), do: {nil, description}

  defp parse_link_arrows(arrows) when is_list(arrows) and length(arrows) > 0 do
    arrows
    |> Enum.map_join(&@arrow_mapping[&1])
    # Add invisible character to force mobile to show small emojis
    |> then(&(&1 <> "‎"))
  end

  defp parse_link_arrows(_), do: nil

  defp parse_card_race(race) when is_map_key(@card_type_mapping, race) do
    @card_type_mapping[race]
  end

  defp parse_card_race(race), do: race

  defp get_card_type(type) do
    case type do
      "Monster" -> :monster
      "Spell" -> :spell
      "Trap" -> :trap
      _ -> nil
    end
  end

  defp get_monster_type([type | types]) do
    case type do
      "Synchro" -> :synchro
      "Effect" -> :effect
      "Normal" -> :normal
      "Xyz" -> :xyz
      "Fusion" -> :fusion
      "Ritual" -> :ritual
      "Link" -> :link
      # Skip Pendulum and Flip monsters as this is used for color and level name
      "Pendulum" -> get_monster_type(types)
      "Flip" -> get_monster_type(types)
      _ -> nil
    end
  end

  defp get_monster_type(_), do: nil
end
