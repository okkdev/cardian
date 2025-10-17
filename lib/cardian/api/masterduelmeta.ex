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
    |> Stream.filter(&(&1["konamiID"] != nil))
    |> Enum.to_list()
  end

  def update_card_details(cards, raw_md_cards) do
    md_cards_by_id = raw_md_cards |> Enum.map(&{&1["konamiID"], &1}) |> Enum.into(%{})

    Enum.map(cards, &cast_md_details(&1, md_cards_by_id))
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
