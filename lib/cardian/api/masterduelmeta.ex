defmodule Cardian.Api.Masterduelmeta do
  alias Cardian.Struct.{Card, Set}

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

  def get_all_cards_raw() do
    with {:ok, count} <- get_card_amount() do
      pages = ceil(count / 3000)

      results =
        1..pages
        |> Task.async_stream(fn page ->
          url =
            "#{@url}/cards?limit=3000&page=#{page}"
            |> URI.encode()

          Req.request(url: url)
          |> handle_response()
        end)
        |> Enum.to_list()

      case Enum.find(results, &match?({:ok, {:error, _}}, &1)) do
        nil ->
          cards =
            results
            |> Enum.flat_map(fn {:ok, {:ok, body}} ->
              Enum.filter(body, &(&1["alternateArt"] != true and &1["konamiID"] != nil))
            end)

          {:ok, cards}

        {:ok, {:error, reason}} ->
          {:error, reason}
      end
    end
  end

  def update_card_details(cards, raw_md_cards) do
    md_cards_by_id = raw_md_cards |> Enum.map(&{&1["konamiID"], &1}) |> Enum.into(%{})

    Enum.map(cards, &cast_md_details(&1, md_cards_by_id))
  end

  def get_card_amount() do
    url =
      (@url <> "/cards?collectionCount=true")
      |> URI.encode()

    case Req.request(url: url) do
      {:ok, res} ->
        {:ok, String.to_integer(res.body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_all_sets() do
    with {:ok, count} <- get_sets_amount() do
      pages = ceil(count / 3000)

      1..pages
      |> Enum.reduce_while({:ok, []}, fn page, {:ok, acc} ->
        url =
          "#{@url}/sets?limit=3000&page=#{page}"
          |> URI.encode()

        case Req.request(url: url) |> handle_response() do
          {:ok, body} -> {:cont, {:ok, acc ++ body}}
          {:error, _} = err -> {:halt, err}
        end
      end)
      |> case do
        {:ok, raw_sets} -> {:ok, Enum.map(raw_sets, &cast_set/1)}
        {:error, _} = err -> err
      end
    end
  end

  def get_sets_amount() do
    url =
      (@url <> "/sets?collectionCount=true")
      |> URI.encode()

    case Req.request(url: url) do
      {:ok, res} ->
        {:ok, String.to_integer(res.body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_set_link(url_path) when is_binary(url_path) do
    ("https://www.masterduelmeta.com/articles" <> url_path)
    |> URI.encode()
  end

  defp get_set_link(_), do: nil

  defp handle_response(resp) do
    case resp do
      {:ok, res} ->
        {:ok, res.body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp cast_md_details(%Card{} = card, md_cards) do
    case Map.fetch(md_cards, card.id) do
      {:ok, md_card} ->
        %{
          card
          | status_md: @status_mapping[md_card["banStatus"]],
            rarity_md: @rarity_mapping[md_card["rarity"]],
            sets_md: Enum.map(md_card["obtain"], & &1["source"]["_id"])
        }

      :error ->
        card
    end
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
end
