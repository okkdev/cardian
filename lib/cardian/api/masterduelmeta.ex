defmodule Cardian.Api.Masterduelmeta do
  require Logger
  alias Cardian.Model.{Card, Set}

  @url "https://www.masterduelmeta.com/api/v1"

  def get_card_by_name(name) when is_binary(name) do
    url =
      (@url <> "/cards?name=" <> name)
      |> URI.encode()

    Finch.build(:get, url)
    |> Finch.request(MyFinch)
    |> handle_response()
    |> Enum.map(&cast_card/1)
  end

  def get_card_by_id(id) when is_binary(id) do
    url =
      (@url <> "/cards?_id=" <> id)
      |> URI.encode()

    Finch.build(:get, url)
    |> Finch.request(MyFinch)
    |> handle_response()
    |> Enum.map(&cast_card/1)
  end

  def search_card(name) when is_binary(name) do
    url =
      "#{@url}/cards?search=#{name}&limit=25&cardSort=popRank&aggregate=search"
      |> URI.encode()

    Finch.build(:get, url)
    |> Finch.request(MyFinch)
    |> handle_response()
    |> Enum.map(&cast_card/1)
  end

  def get_card(card) when is_binary(card) do
    if object_id?(card) do
      get_card_by_id(card)
    else
      search_card(card)
    end
  end

  def get_sets_by_id(sets) when is_list(sets) do
    url =
      sets
      |> Enum.join(",")
      |> then(&"#{@url}/sets?_id[$in]=#{&1}")
      |> URI.encode()

    Finch.build(:get, url)
    |> Finch.request(MyFinch)
    |> handle_response()
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

  # Legacy set link generation
  # def get_set_link(set_name) when is_binary(set_name) do
  #   set_name
  #   |> String.downcase()
  #   |> String.replace(" ", "-")
  #   |> then(&("https://www.masterduelmeta.com/articles/sets/" <> &1))
  #   |> URI.encode()
  # end

  defp handle_response(resp) do
    case resp do
      {:ok, res} ->
        Jason.decode!(res.body)

      {:error, reason} ->
        Logger.error(reason)
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
      sets: get_sets(resp["obtain"])
    }
  end

  defp get_sets(sets) when length(sets) > 0 do
    sets
    |> Enum.map(& &1["source"]["_id"])
    |> get_sets_by_id()
    |> Enum.map(
      &%Set{
        name: &1["name"],
        url: get_set_link(&1["linkedArticle"]["url"])
      }
    )
  end

  defp get_sets(_) do
    []
  end

  defp parse_effects("[ Pendulum Effect ]" <> description) do
    [pendulum_effect, rest] = String.split(description, "---", parts: 2)
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

  defp object_id?(object_id) do
    String.match?(object_id, ~r/^[a-fA-F0-9]{24}$/)
  end
end
