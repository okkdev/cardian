defmodule Cardian.Api.Duellinksmeta do
  alias Cardian.Struct.{Card, Set}

  @url "https://www.duellinksmeta.com/api/v1"

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

  def update_card_details(cards, raw_dl_cards) do
    dl_cards_by_id = raw_dl_cards |> Enum.map(&{&1["konamiID"], &1}) |> Enum.into(%{})

    Enum.map(cards, &cast_dl_details(&1, dl_cards_by_id))
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
    ("https://www.duellinksmeta.com/articles" <> url_path)
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

  defp cast_dl_details(%Card{} = card, dl_cards) do
    case Map.fetch(dl_cards, card.id) do
      {:ok, dl_card} ->
        %{
          card
          | status_dl: @status_mapping[dl_card["banStatus"]],
            rarity_dl: @rarity_mapping[dl_card["rarity"]],
            sets_dl: Enum.map(dl_card["obtain"], & &1["source"]["_id"])
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
