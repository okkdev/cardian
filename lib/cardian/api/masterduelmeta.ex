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
