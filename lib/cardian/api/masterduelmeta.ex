defmodule Cardian.Api.Masterduelmeta do
  require Logger

  @url "https://www.masterduelmeta.com/api/v1"

  def get_card_by_name(name) when is_binary(name) do
    url =
      (@url <> "/cards?name=" <> name)
      |> URI.encode()

    Finch.build(:get, url)
    |> Finch.request(MyFinch)
    |> handle_response()
  end

  def get_card_by_id(id) when is_binary(id) do
    url =
      (@url <> "/cards?_id=" <> id)
      |> URI.encode()

    Finch.build(:get, url)
    |> Finch.request(MyFinch)
    |> handle_response()
  end

  def search_card(name) when is_binary(name) do
    url =
      "#{@url}/cards?search=#{name}&limit=25&cardSort=popRank&aggregate=search"
      |> URI.encode()

    Finch.build(:get, url)
    |> Finch.request(MyFinch)
    |> handle_response()
  end

  def get_card(card) when is_binary(card) do
    if object_id?(card) do
      get_card_by_id(card)
    else
      search_card(card)
    end
  end

  def get_image(card_id) when is_binary(card_id) do
    "https://s3.duellinksmeta.com/cards/#{card_id}_w420.webp"
    |> URI.encode()
  end

  def get_card_link(card_name) when is_binary(card_name) do
    ("https://www.masterduelmeta.com/cards/" <> card_name)
    |> URI.encode()
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

  def get_set_link(url_path) do
    "https://www.masterduelmeta.com/articles" <> url_path
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

  defp object_id?(object_id) do
    String.match?(object_id, ~r/^[a-fA-F0-9]{24}$/)
  end
end
