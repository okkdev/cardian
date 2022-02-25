defmodule Cardian.Api.Masterduelmeta do
  alias Cardian.Model.{Card, Set}

  @url "https://www.masterduelmeta.com/api/v1"

  def get_all_cards() do
    pages = ceil(get_card_amount() / 3000)

    Enum.flat_map(Enum.to_list(1..pages), fn page ->
      url =
        "#{@url}/cards?limit=3000&page=#{page}"
        |> URI.encode()

      Finch.build(:get, url)
      |> Finch.request(MyFinch)
      |> handle_response()
    end)
    |> Enum.map(&cast_card/1)
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

    Enum.flat_map(Enum.to_list(1..pages), fn page ->
      url =
        "#{@url}/sets?limit=3000&page=#{page}"
        |> URI.encode()

      Finch.build(:get, url)
      |> Finch.request(MyFinch)
      |> handle_response()
    end)
    |> Enum.map(&cast_set/1)
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
    "https://s3.duellinksmeta.com/cards/#{card_id}_w420.webp"
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

  defp get_set_link(_) do
    nil
  end

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
      status: resp["banStatus"] || "Unlimited",
      rarity: resp["rarity"],
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

  defp parse_effects(description) do
    {nil, description}
  end

  defp parse_link_arrows(arrows) when is_list(arrows) and length(arrows) > 0 do
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
    # Add invisible character to force mobile to show small emojis
    |> then(&(&1 <> "‎"))
  end

  defp parse_link_arrows(_) do
    nil
  end

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
      # Get the second type of pendulum monsters as this is used for color and level name
      "Pendulum" -> get_monster_type(types)
      _ -> nil
    end
  end

  defp get_monster_type(_) do
    nil
  end
end
