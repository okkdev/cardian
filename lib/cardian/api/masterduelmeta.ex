defmodule Cardian.Api.Masterduelmeta do
  alias Cardian.Model.{Card, Set}

  @url "https://www.masterduelmeta.com/api/v1"

  @rarity_mapping %{
    "N" => :normal,
    "R" => :rare,
    "SR" => :super,
    "UR" => :ultra
  }

  @status_mapping %{
    "Limited 2" => :semilimited,
    "Limited 1" => :limited,
    "Forbidden" => :forbidden
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

  def get_all_cards() do
    pages = ceil(get_card_amount() / 3000)

    1..pages
    |> Task.async_stream(fn page ->
      url =
        "#{@url}/cards?limit=3000&page=#{page}"
        |> URI.encode()

      Req.request(url: url)
      |> handle_response()
    end)
    |> Stream.flat_map(fn {:ok, res} -> res end)
    |> Stream.filter(&(&1["alternateArt"] != true))
    |> Task.async_stream(&cast_card/1)
    |> Stream.map(fn {:ok, card} -> card end)
    |> Stream.filter(&(&1.id != nil))
    |> Enum.to_list()
  end

  def get_card_amount() do
    url =
      (@url <> "/cards?collectionCount=true")
      |> URI.encode()

    Req.request(url: url)
    |> case do
      {:ok, res} ->
        String.to_integer(res.body)

      {:error, reason} ->
        raise(inspect(reason))
    end
  end

  def get_all_sets() do
    pages = ceil(get_sets_amount() / 3000)

    1..pages
    |> Stream.flat_map(fn page ->
      url =
        "#{@url}/sets?limit=3000&page=#{page}"
        |> URI.encode()

      Req.request(url: url)
      |> handle_response()
    end)
    |> Stream.map(&cast_set/1)
    |> Enum.to_list()
  end

  def get_sets_amount() do
    url =
      (@url <> "/sets?collectionCount=true")
      |> URI.encode()

    Req.request(url: url)
    |> case do
      {:ok, res} ->
        String.to_integer(res.body)

      {:error, reason} ->
        raise(inspect(reason))
    end
  end

  defp get_image(card_id) when is_binary(card_id) do
    "https://imgserv.duellinksmeta.com/v2/mdm/card/#{card_id}?portrait=true"
    |> URI.encode()
  end

  defp get_image(_), do: nil

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
        res.body

      {:error, reason} ->
        raise(inspect(reason))
    end
  end

  defp cast_card(resp) do
    {pendulum_effect, description} = parse_effects(resp["description"])

    %Card{
      id: resp["konamiID"],
      type: get_card_type(resp["type"]),
      race: resp["race"],
      monster_type: get_monster_type(resp["monsterType"]),
      monster_types: resp["monsterType"],
      attribute: resp["attribute"],
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
      type: resp["type"],
      url: get_set_link(resp["linkedArticle"]["url"]),
      image_url: "https://s3.duellinksmeta.com" <> resp["bannerImage"]
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

  defp get_card_type(type) do
    case String.downcase(type) do
      "monster" -> :monster
      "spell" -> :spell
      "trap" -> :trap
      _ -> nil
    end
  end

  defp get_monster_type([type | types]) do
    case String.downcase(type) do
      "synchro" -> :synchro
      "effect" -> :effect
      "normal" -> :normal
      "xyz" -> :xyz
      "fusion" -> :fusion
      "ritual" -> :ritual
      "link" -> :link
      # Skip Pendulum and Flip monsters as this is used for color and level name
      "pendulum" -> get_monster_type(types)
      "flip" -> get_monster_type(types)
      _ -> nil
    end
  end

  defp get_monster_type(_), do: nil
end
