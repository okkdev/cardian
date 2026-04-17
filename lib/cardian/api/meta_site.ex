defmodule Cardian.Api.MetaSite do
  alias Cardian.Struct.{Card, Set}

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

  def get_all_cards_raw(config) do
    with {:ok, count} <- get_collection_count(config, "cards") do
      pages = ceil(count / 3000)

      1..pages
      |> Task.async_stream(fn page ->
        url =
          "#{config.base_url}/cards?limit=3000&page=#{page}"
          |> URI.encode()

        Req.request(url: url)
        |> handle_response()
      end)
      |> Enum.reduce_while({:ok, []}, fn
        {:ok, {:ok, body}}, {:ok, acc} ->
          cards = Enum.filter(body, &(&1["alternateArt"] != true and &1["konamiID"] != nil))
          {:cont, {:ok, acc ++ cards}}

        {:ok, {:error, reason}}, _ ->
          {:halt, {:error, reason}}
      end)
    end
  end

  def update_card_details(cards, raw_cards, config) do
    cards_by_id = raw_cards |> Enum.map(&{&1["konamiID"], &1}) |> Enum.into(%{})

    Enum.map(cards, &cast_details(&1, cards_by_id, config))
  end

  def get_all_sets(config) do
    with {:ok, count} <- get_collection_count(config, "sets") do
      pages = ceil(count / 3000)

      1..pages
      |> Enum.reduce_while({:ok, []}, fn page, {:ok, acc} ->
        url =
          "#{config.base_url}/sets?limit=3000&page=#{page}"
          |> URI.encode()

        case Req.request(url: url) |> handle_response() do
          {:ok, body} -> {:cont, {:ok, acc ++ body}}
          {:error, _} = err -> {:halt, err}
        end
      end)
      |> case do
        {:ok, raw_sets} -> {:ok, Enum.map(raw_sets, &cast_set(&1, config))}
        {:error, _} = err -> err
      end
    end
  end

  defp get_collection_count(config, resource) do
    url =
      "#{config.base_url}/#{resource}?collectionCount=true"
      |> URI.encode()

    case Req.request(url: url) do
      {:ok, res} ->
        {:ok, String.to_integer(res.body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_response({:ok, res}), do: {:ok, res.body}
  defp handle_response({:error, reason}), do: {:error, reason}

  defp cast_details(%Card{} = card, cards_by_id, config) do
    case Map.fetch(cards_by_id, card.id) do
      {:ok, raw_card} ->
        %{
          card
          | config.status_field => @status_mapping[raw_card["banStatus"]],
            config.rarity_field => @rarity_mapping[raw_card["rarity"]],
            config.sets_field => Enum.map(raw_card["obtain"], & &1["source"]["_id"])
        }

      :error ->
        card
    end
  end

  defp cast_set(resp, config) do
    %Set{
      id: resp["_id"],
      name: resp["name"],
      type: resp["type"],
      url: get_set_link(resp["linkedArticle"]["url"], config),
      image_url: "https://s3.duellinksmeta.com" <> resp["bannerImage"]
    }
  end

  defp get_set_link(url_path, config) when is_binary(url_path) do
    (config.site_prefix <> url_path)
    |> URI.encode()
  end

  defp get_set_link(_, _), do: nil
end
