defmodule Cardian.Api.Images do
  def get_image(card_id) when is_binary(card_id) do
    if image_url(card_id) |> available?() do
      {:ok, image_url(card_id)}
    else
      if remote_image_url(card_id) |> available?() do
        {:ok, remote_image_url(card_id)}
      else
        {:error, "Card image not found"}
      end
    end
  end

  def available?(image_url) when is_binary(image_url) do
    image_url
    |> then(&Finch.build(:head, &1))
    |> Finch.request(MyFinch)
    |> then(fn {:ok, %{status: status}} -> status == 200 end)
  end

  defp image_url(card_id) when is_binary(card_id) do
    "https://s3.lain.dev/ygo/#{card_id}.webp"
    |> URI.encode()
  end

  defp remote_image_url(card_id) when is_binary(card_id) do
    "https://storage.googleapis.com/ygoprodeck.com/pics_artgame/#{card_id}.jpg"
    |> URI.encode()
  end
end
